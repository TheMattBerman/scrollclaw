#!/usr/bin/env python3
"""Generate a first frame image via Nano Banana 2 for Sora i2v input.

Supports two providers:
  - replicate (default): google/nano-banana-2 via api.replicate.com
  - fal: fal-ai/nano-banana-2 via queue.fal.run (matches generate-clip.sh pattern)

Reads creator profile to inject identity traits into the prompt.
Saves output immediately — ephemeral URLs are not acceptable.

Usage:
  # Default (Replicate)
  python3 generate-first-frame.py --prompt-file p.txt --output-file f.png

  # Via fal.ai (single-vendor billing with Sora 2 i2v on the same host)
  python3 generate-first-frame.py --provider fal --prompt-file p.txt --output-file f.png
"""
import argparse
import json
import os
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime


def load_text(path):
    return Path(path).read_text(encoding='utf-8')


def http_json(method, url, headers, payload=None):
    body = json.dumps(payload).encode('utf-8') if payload else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode('utf-8'))


def download_file(url, dest):
    req = urllib.request.Request(url, headers={'User-Agent': 'sora-ugc/1.0'})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    Path(dest).parent.mkdir(parents=True, exist_ok=True)
    with open(dest, 'wb') as f:
        f.write(data)
    return len(data)


def append_log(log_path, row):
    path = Path(log_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text('# Output Log\n\n| Timestamp | Label | Model | Prompt File | Provider URL | Saved File | Notes |\n|---|---|---|---|---|---|---|\n', encoding='utf-8')
    with open(path, 'a', encoding='utf-8') as f:
        f.write(f"| {row['timestamp']} | {row['label']} | {row['model']} | {row['prompt_file']} | {row['provider_url']} | {row['saved_file']} | {row['notes']} |\n")


# ---------------------------------------------------------------------------
# Replicate provider
# ---------------------------------------------------------------------------

def replicate_headers(token):
    return {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }


def create_prediction_replicate(token, model, prompt, aspect_ratio='9:16', output_format='png'):
    owner, name = model.split('/', 1)
    url = f'https://api.replicate.com/v1/models/{owner}/{name}/predictions'
    payload = {
        'input': {
            'prompt': prompt,
            'aspect_ratio': aspect_ratio,
            'output_format': output_format,
        }
    }
    return http_json('POST', url, replicate_headers(token), payload)


def poll_prediction_replicate(token, get_url, poll_seconds=3, timeout_seconds=300):
    started = time.time()
    while True:
        data = http_json('GET', get_url, replicate_headers(token))
        status = data.get('status')
        if status == 'succeeded':
            return data
        if status in ('failed', 'canceled'):
            raise RuntimeError(f"Prediction {status}: {data.get('error', 'unknown error')}")
        if time.time() - started > timeout_seconds:
            raise TimeoutError(f'Timed out after {timeout_seconds}s')
        time.sleep(poll_seconds)


def extract_output_urls(prediction):
    output = prediction.get('output')
    if isinstance(output, list):
        return [x for x in output if isinstance(x, str)]
    if isinstance(output, str):
        return [output]
    if isinstance(output, dict):
        urls = []
        for v in output.values():
            if isinstance(v, str) and v.startswith('http'):
                urls.append(v)
            elif isinstance(v, list):
                urls.extend([x for x in v if isinstance(x, str) and x.startswith('http')])
        return urls
    return []


def run_replicate(token, model, prompt, aspect_ratio, output_format, output_file, poll_seconds, timeout_seconds):
    prediction = create_prediction_replicate(token, model, prompt, aspect_ratio, output_format)
    result = poll_prediction_replicate(token, prediction['urls']['get'], poll_seconds, timeout_seconds)
    urls = extract_output_urls(result)
    if not urls:
        raise RuntimeError('No downloadable output URL found')
    size = download_file(urls[0], output_file)
    return urls[0], size


# ---------------------------------------------------------------------------
# fal.ai provider
# ---------------------------------------------------------------------------
# Endpoint matches generate-clip.sh queue pattern: queue.fal.run/fal-ai/<model>
# Returns persistent v3b.fal.media URL — ideal as input to fal Sora i2v.

FAL_ENDPOINTS = {
    'fal-ai/nano-banana-2': 'https://queue.fal.run/fal-ai/nano-banana-2',
    'fal-ai/nano-banana-pro': 'https://queue.fal.run/fal-ai/nano-banana-pro',
}


def fal_headers(api_key):
    return {
        'Authorization': f'Key {api_key}',
        'Content-Type': 'application/json',
    }


def submit_fal(api_key, model, prompt, aspect_ratio):
    endpoint = FAL_ENDPOINTS.get(model)
    if not endpoint:
        raise RuntimeError(f"Unknown fal model: {model}. Known: {list(FAL_ENDPOINTS)}")
    payload = {
        'prompt': prompt,
        'aspect_ratio': aspect_ratio,
        'num_images': 1,
    }
    return http_json('POST', endpoint, fal_headers(api_key), payload)


def poll_fal(api_key, status_url, poll_seconds=3, timeout_seconds=300):
    started = time.time()
    while True:
        data = http_json('GET', status_url, fal_headers(api_key))
        status = data.get('status')
        if status == 'COMPLETED':
            return data
        if status in ('FAILED', 'CANCELED'):
            raise RuntimeError(f"fal generation {status}: {data}")
        if time.time() - started > timeout_seconds:
            raise TimeoutError(f'Timed out after {timeout_seconds}s')
        time.sleep(poll_seconds)


def run_fal(api_key, model, prompt, aspect_ratio, output_file, poll_seconds, timeout_seconds):
    submit = submit_fal(api_key, model, prompt, aspect_ratio)
    status_url = submit.get('status_url')
    response_url = submit.get('response_url')
    if not status_url or not response_url:
        raise RuntimeError(f'fal submit failed: {submit}')
    poll_fal(api_key, status_url, poll_seconds, timeout_seconds)
    result = http_json('GET', response_url, fal_headers(api_key))
    images = result.get('images') or []
    if not images:
        raise RuntimeError(f'fal returned no images: {result}')
    url = images[0].get('url')
    if not url:
        raise RuntimeError(f'fal image missing url: {images[0]}')
    size = download_file(url, output_file)
    return url, size


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

PROVIDER_DEFAULTS = {
    'replicate': {
        'model': 'google/nano-banana-2',
        'fallback_model': 'google/nano-banana-pro',
        'env_var': 'REPLICATE_API_TOKEN',
    },
    'fal': {
        'model': 'fal-ai/nano-banana-2',
        'fallback_model': 'fal-ai/nano-banana-pro',
        'env_var': 'FAL_KEY',
    },
}


def main():
    ap = argparse.ArgumentParser(description='Generate first frame via Nano Banana for Sora i2v.')
    ap.add_argument('--prompt-file', required=True, help='Text file with the image prompt')
    ap.add_argument('--output-file', required=True, help='Where to save the generated image')
    ap.add_argument('--creator', help='Path to creator profile .md (optional, for identity context)')
    ap.add_argument('--log-file', default=None, help='Output log file path (optional, skip logging if omitted)')
    ap.add_argument('--label', default='frame1', help='Label for log entry')
    ap.add_argument('--provider', choices=['replicate', 'fal'], default='replicate',
                    help='Image generation provider (default: replicate)')
    ap.add_argument('--model', default=None,
                    help='Model id. Default per provider: replicate=google/nano-banana-2, fal=fal-ai/nano-banana-2')
    ap.add_argument('--fallback-model', default=None,
                    help='Fallback model id. Default per provider: replicate=google/nano-banana-pro, fal=fal-ai/nano-banana-pro')
    ap.add_argument('--aspect-ratio', default='9:16', help='Aspect ratio')
    ap.add_argument('--output-format', default='png', help='Output format (replicate only — fal returns PNG)')
    ap.add_argument('--poll-seconds', type=int, default=3)
    ap.add_argument('--timeout-seconds', type=int, default=300)
    ap.add_argument('--no-fallback', action='store_true')
    args = ap.parse_args()

    defaults = PROVIDER_DEFAULTS[args.provider]
    model = args.model or defaults['model']
    fallback_model = args.fallback_model or defaults['fallback_model']
    env_var = defaults['env_var']

    token = os.environ.get(env_var)
    if not token:
        print(f'{env_var} is not set', file=sys.stderr)
        sys.exit(2)

    prompt = load_text(args.prompt_file).strip()

    # If creator profile provided, prepend identity traits as context
    if args.creator and Path(args.creator).exists():
        creator_text = load_text(args.creator)
        if '## Prompt Invariants' in creator_text:
            invariants = creator_text.split('## Prompt Invariants')[1].split('##')[0].strip()
            prompt = f"{invariants}\n\nScene: {prompt}"

    models = [model] + ([] if args.no_fallback else [fallback_model])
    last_error = None

    for idx, m in enumerate(models):
        try:
            if args.provider == 'replicate':
                provider_url, size = run_replicate(token, m, prompt, args.aspect_ratio,
                                                    args.output_format, args.output_file,
                                                    args.poll_seconds, args.timeout_seconds)
            else:
                provider_url, size = run_fal(token, m, prompt, args.aspect_ratio,
                                              args.output_file, args.poll_seconds,
                                              args.timeout_seconds)
            if args.log_file:
                append_log(args.log_file, {
                    'timestamp': datetime.now().isoformat(timespec='seconds'),
                    'label': args.label,
                    'model': m,
                    'prompt_file': args.prompt_file,
                    'provider_url': provider_url,
                    'saved_file': args.output_file,
                    'notes': f'saved ({size} bytes) via {args.provider}' + (' (fallback)' if idx > 0 else ''),
                })
            print(json.dumps({
                'ok': True,
                'provider': args.provider,
                'model': m,
                'output_file': args.output_file,
                'provider_url': provider_url,
                'bytes': size,
                'fallback_used': idx > 0,
            }, indent=2))
            return
        except Exception as e:
            last_error = str(e)
            if args.log_file:
                append_log(args.log_file, {
                    'timestamp': datetime.now().isoformat(timespec='seconds'),
                    'label': args.label,
                    'model': m,
                    'prompt_file': args.prompt_file,
                    'provider_url': 'n/a',
                    'saved_file': 'n/a',
                    'notes': f'failed via {args.provider}: {last_error}',
                })
            if idx == len(models) - 1:
                print(json.dumps({'ok': False, 'provider': args.provider, 'error': last_error}, indent=2), file=sys.stderr)
                sys.exit(1)


if __name__ == '__main__':
    main()
