#!/bin/bash  
sleep 30
sudo apt-get update -y
sudo apt-get install python3-fastapi python3-uvicorn -y && sudo apt-get install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install