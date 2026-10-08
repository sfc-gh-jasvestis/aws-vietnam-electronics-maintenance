"""Publish simulated machine telemetry to AWS IoT Core (topic vn/maint/telemetry).

The IoT rule lands each message in S3; Snowpipe loads it into RAW.LIVE_TELEMETRY.
Machine IDs come from RAW.MACHINES (MAC-0000..MAC-0019). Values are seeded random.
"""
import argparse
import json
import random
from datetime import datetime, timezone


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--region', default='us-west-2')
    ap.add_argument('--count', type=int, default=40)
    ap.add_argument('--seed', type=int)
    args = ap.parse_args()
    import boto3
    iot = boto3.client('iot', region_name=args.region)
    endpoint = iot.describe_endpoint(endpointType='iot:Data-ATS')['endpointAddress']
    data = boto3.client('iot-data', region_name=args.region, endpoint_url=f'https://{endpoint}')
    rng = random.Random(args.seed)
    for _ in range(args.count):
        machine = f'MAC-{rng.randint(0, 19):04d}'
        alarm = rng.random() < 0.1
        msg = {'machine_id': machine,
               'event_ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3],
               'vibration_mm_s': round(rng.gauss(7.5 if alarm else 3.0, 0.8), 2),
               'temperature_c': round(rng.gauss(78 if alarm else 55, 4), 1),
               'status': 'ALARM' if alarm else 'RUNNING'}
        data.publish(topic='vn/maint/telemetry', qos=1, payload=json.dumps(msg))
    print(f'published {args.count} messages to vn/maint/telemetry via {endpoint}')


if __name__ == '__main__':
    main()
