#!/bin/bash
sudo -i;
echo -e ":::: installing sshfsm :::::\n";
echo -e ":::: the script will then (or should) start automatically when computer start and WIFI is ready ::::\n";
echo -e "\n";
echo -e ":::: copy mountnas.conf in /etc/init/ ::::\n";
cp mountnas.conf /etc/init/mountnas.conf;
echo -e ":::: copy sshfsm in /bin/sshfsm ::::\n";
cp sshfsm /bin/sshfsm;
exit
