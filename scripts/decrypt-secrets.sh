#!/bin/bash

echo -e "Decrypting secrets. You will be prompted for a password..."
gpg --decrypt-files config/secret/*.gpg
