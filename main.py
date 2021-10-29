#!/usr/bin/python3

from typing import List, Dict, Callable, Tuple
import requests
import argparse
import sys
import os


def get_urls(file: str) -> List[str]:
    print(f"Reading URL's from {file}")

    url_list = []  # Just a safety thing, should not be needed but anyway
    with open(file, 'r') as f:
        url_list = [line.strip() for line in f]
        # url_list = f.readlines()
        # f.seek(0)

    return url_list


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("urlfile", type=str, help="The file which contains the list of URL's to check")
    parser.add_argument("secretsfile", type=str, help="The file which contains the 'secrets'")
    return parser.parse_args()


def get_ip_netifaces() -> Dict[str, str]:
    import netifaces

    out_list = {}
    for interface in netifaces.interfaces():
        addresses = netifaces.ifaddresses(interface)
        if netifaces.AF_INET in addresses and 'addr' in addresses[netifaces.AF_INET][0].keys():
            out_list[interface] = addresses[netifaces.AF_INET][0]['addr']

    return out_list


GET_IP_FACTORY: Dict[str, Callable] = {"netifaces": get_ip_netifaces}


def get_userpass(secrets_file: str) -> Tuple[str, str]:
    with open(secrets_file, 'r') as f:
        contents = [line.strip() for line in f]
        if len(contents) > 3:
            print("Euhm, I got more then I asked for in the secrets, fuck you")
            raise Exception(f"Too much info in secrets. Expected 2 lines, found {len(contents)}")

        username = contents[0]

        # If we find the username in the lookup, we use the serialnumber getter provided
        if username in GET_SERIAL_FACTORY.keys():
            username = GET_SERIAL_FACTORY[username]()

        password = contents[1]
    return username, password


def get_serial_rpi() -> str:
    # command = "cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2"
    # This lower one seems to work on more devices
    command = "cat /sys/firmware/devicetree/base/serial-number"
    serial = os.popen(command).read().replace("\n", "")
    return serial


def get_serial_apple() -> str:
    # ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}'
    command = "ioreg -c IOPlatformExpertDevice -d 2 | awk -F\\\" '/IOPlatformSerialNumber/{print $(NF-1)}'"
    serial = os.popen(command).read().replace("\n", "")
    return serial


GET_SERIAL_FACTORY: Dict[str, Callable] = {'mac': get_serial_apple,
                                           "rpi": get_serial_rpi}

if __name__ == "__main__":

    if sys.platform not in ['linux', 'darwin']:
        print("Only tested on Linux, aborting.")
        exit(0)

    args = parse_args()

    url_file = args.urlfile
    secrets_file = args.secretsfile

    urls = get_urls(url_file)
    print(f"Asking {len(urls)} url's for response.")
    for url in urls:
        print(f"{url} :")
        try:
            resp = requests.post(url, json={"ip": GET_IP_FACTORY['netifaces']()}, auth=get_userpass(secrets_file), timeout=5)
            print(f"{resp.status_code} :: {resp.text}")
        except Exception as e:
            print(f"Some exception : {e}")
        finally:
            print("---------------------------")

    print("Done, bye.")
