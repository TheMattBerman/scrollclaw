#!/usr/bin/env python3
"""Generate a first frame image via Nano Banana 2 (Replicate) for Sora i2v input.

Reads creator profile to inject identity traits into the prompt.
Saves output immediately — ephemeral URLs are not acceptable.
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


def http_json(method, url, token, payload=None):
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }
    data = json.dumps(payload).encode('utf-8') if payload else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
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


def create_prediction(token, model, prompt, aspect_ratio='9:16', output_format='png'):
    owner, name = model.split('/', 1)
    url = f'https://api.replicate.com/v1/models/{owner}/{name}/predictions'
    payload = {
        'input': {
            'prompt': prompt,
            'aspect_ratio': aspect_ratio,
            'output_format': output_format,
        }
    }
    return http_json('POST', url, token, payload)


def poll_prediction(token, get_url, poll_seconds=3, timeout_seconds=300):
    started = time.time()
    while True:
        data = http_json('GET', get_url, token)
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


def main():
    ap = argparse.ArgumentParser(description='Generate first frame via Nano Banana for Sora i2v.')
    ap.add_argument('--prompt-file', required=True, help='Text file with the image prompt')
    ap.add_argument('--output-file', required=True, help='Where to save the generated image')
    ap.add_argument('--creator', help='Path to creator profile .md (optional, for identity context)')
    ap.add_argument('--log-file', default=None, help='Output log file path (optional, skip logging if omitted)')
    ap.add_argument('--label', default='frame1', help='Label for log entry')
    ap.add_argument('--model', default='google/nano-banana-2', help='Image generation model')
    ap.add_argument('--fallback-model', default='google/nano-banana-pro', help='Fallback model')
    ap.add_argument('--aspect-ratio', default='9:16', help='Aspect ratio')
    ap.add_argument('--output-format', default='png', help='Output format')
    ap.add_argument('--poll-seconds', type=int, default=3)
    ap.add_argument('--timeout-seconds', type=int, default=300)
    ap.add_argument('--no-fallback', action='store_true')
    args = ap.parse_args()

    token = os.environ.get('REPLICATE_API_TOKEN')
    if not token:
        print('REPLICATE_API_TOKEN is not set', file=sys.stderr)
        sys.exit(2)

    prompt = load_text(args.prompt_file).strip()

    # If creator profile provided, prepend identity traits as context
    if args.creator and Path(args.creator).exists():
        creator_text = load_text(args.creator)
        # Extract prompt invariants section if present
        if '## Prompt Invariants' in creator_text:
            invariants = creator_text.split('## Prompt Invariants')[1].split('##')[0].strip()
            prompt = f"{invariants}\n\nScene: {prompt}"

    models = [args.model] + ([] if args.no_fallback else [args.fallback_model])
    last_error = None

    for idx, model in enumerate(models):
        try:
            prediction = create_prediction(token, model, prompt, args.aspect_ratio, args.output_format)
            result = poll_prediction(token, prediction['urls']['get'], args.poll_seconds, args.timeout_seconds)
            urls = extract_output_urls(result)
            if not urls:
                raise RuntimeError('No downloadable output URL found')
            size = download_file(urls[0], args.output_file)
            if args.log_file:
                append_log(args.log_file, {
                    'timestamp': datetime.now().isoformat(timespec='seconds'),
                    'label': args.label,
                    'model': model,
                    'prompt_file': args.prompt_file,
                    'provider_url': urls[0],
                    'saved_file': args.output_file,
                    'notes': f'saved ({size} bytes)' + (' via fallback' if idx > 0 else ''),
                })
            print(json.dumps({
                'ok': True,
                'model': model,
                'output_file': args.output_file,
                'provider_url': urls[0],
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
                    'model': model,
                    'prompt_file': args.prompt_file,
                    'provider_url': 'n/a',
                    'saved_file': 'n/a',
                    'notes': f'failed: {last_error}',
                })
            if idx == len(models) - 1:
                print(json.dumps({'ok': False, 'error': last_error}, indent=2), file=sys.stderr)
                sys.exit(1)


if __name__ == '__main__':
    main()
