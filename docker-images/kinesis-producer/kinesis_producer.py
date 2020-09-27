#!/usr/bin/env python3
# For more information:
#  https://github.com/bufferapp/kiner
from uuid import uuid4
from datetime import datetime
# https://pypi.org/project/names/
import names
import coolname
from random_user_agent.user_agent import UserAgent
from random_user_agent.params import SoftwareName, OperatingSystem
from kiner.producer import KinesisProducer

def on_flush(count, last_flushed_at, Data=b'', PartitionKey='', Metadata=()):
    print(f"""
        Flushed {count} messages at timestamp {last_flushed_at}
        Last message was {Metadata['request_id']} paritioned by {PartitionKey} ({len(Data)} bytes)
    """)


software_names = [SoftwareName.CHROME.value]
operating_systems = [OperatingSystem.WINDOWS.value, OperatingSystem.LINUX.value]

user_agent_rotator = UserAgent(software_names=software_names, operating_systems=operating_systems, limit=100)

# Get list of user agents.
user_agents = user_agent_rotator.get_user_agents()

# Get Random User Agent String.
# user_agent = user_agent_rotator.get_random_user_agent()

p = KinesisProducer('EventStream', flush_callback=on_flush)
for i in range(10):
    _generated = coolname.generate()
    p.put_record(i,
        metadata={
            'request_id': uuid4(),
            'request_timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S.000000"),
            'cookie_id': uuid4(),
            'topic': '.'.join(_generated[:3]),
            "message": "{\"isAffiliate\":false,\"language\":\"es\",\"isRecommendedPalette\":true,\"color\":\"#6d8d79\",\"paletteIndex\":\"0\",\"workspaceId\":\"" +  f"{uuid4()}" + "\"}",
            'message':  "{}.{}".format(names.get_first_name(),names.get_last_name()),
            'environment': _generated[0],
            "website_id": None,
            'user_account_id':  uuid4(),
            "location": "https://cms.jimdo.com/wizard/color-palette/",
            'user_agent': user_agent_rotator.get_random_user_agent(),
            "referrer": "https://register.jimdo.com/es/product"
            },
        partition_key=f"{i % 2}")

p.close()
