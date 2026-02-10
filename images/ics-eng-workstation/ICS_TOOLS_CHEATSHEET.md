# ICS Engineering Tools Cheatsheet

## Modbus TCP
# Read holding registers from PLC
pymodbus.console tcp --host 172.16.5.20 --port 502
# Quick read: python3 -c "from pymodbus.client import ModbusTcpClient; c=ModbusTcpClient('172.16.5.20'); c.connect(); print(c.read_holding_registers(0,10).registers)"

## OPC UA
# Browse OPC UA server
uadiscover opc.tcp://172.16.5.50:4840
uaclient -u opc.tcp://172.16.5.50:4840/cyroid/plc

## EtherNet/IP
# Read tags from EtherNet/IP device
python3 -m cpppo.server.enip.client --address 172.16.5.30:44818 --print "Turbine_Speed_RPM"

## Wireshark ICS Filters
# Modbus: modbus
# DNP3: dnp3
# EtherNet/IP: enip
# OPC UA: opcua
# CIP: cip

## Nmap ICS Scripts
nmap -sV --script modbus-discover -p 502 172.16.5.0/24
nmap -sV --script enip-info -p 44818 172.16.5.0/24
nmap -sV --script opcua-discover -p 4840 172.16.5.0/24
