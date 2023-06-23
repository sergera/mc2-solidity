#!/bin/bash
forge build --extra-output-files evm  --force
rsync -avizh ./. mc2fi:app.mc2.fi-solidity
