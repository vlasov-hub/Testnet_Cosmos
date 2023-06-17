## Installation

Preparing the server for installation (one command)
```bash
sudo apt update && sudo apt upgrade -y && \
sudo apt install curl build-essential git wget jq make gcc tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
```


Installing GO v1.19.2 (one command)
```bash
cd $HOME && \
ver="1.19.2" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version
```
<br>  

Set variables
```bash
CHAIN="okp4-nemeton-1" && \
MONIKER="<YOUR__MONIKER>" && \
WALLET="<YOUR_WALLET_NAME>"

echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile && \
echo "export WALLET=$WALLET" >> $HOME/.bash_profile && \
echo "export CHAIN=$CHAIN" >> $HOME/.bash_profile && \
source $HOME/.bash_profile
```

Build binary 
```bash
git clone https://github.com/okp4/okp4d
cd okp4d
make install
okp4d version
```

Init 
```bash
okp4d init $MONIKER --chain-id $CHAIN && \
okp4d config chain-id $CHAIN && \
okp4d config keyring-backend test && \
```

Wallet
```bash
okp4d keys add $WALLET 
```


Genesis
```bash
wget -O ~/.okp4d/config/genesis.json https://raw.githubusercontent.com/okp4/networks/main/chains/nemeton-1/genesis.json
```
Addrbook
```bash
wget -O $HOME/.okp4d/config/addrbook.json "https://raw.githubusercontent.com/cryptobtcbuyer/Testnet_guides/main/OKP4/addrbook.json"
```

Peers
```bash
PEERS=a009a02a23428538b57591f73ba5a6462c476a70@136.243.88.91:6040,126dc25a6a5aa0cfa83010550dfb3c5a1a861755@65.108.201.15:21337,5c2a752c9b1952dbed075c56c600c3a79b58c395@95.214.55.232:26996,,dcc5b70f1df82def300db6f9dd859c1828514286@65.108.152.201:26656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:36656,8af258bbe73f4c66127a7b3e8b1ec23fde2950a6@65.108.192.123:19656,d1c1b729eff9afe7dfd371f190df6282c82ccfad@37.187.144.187:31656,a49302f8999e5a953ebae431c4dde93479e17155@141.95.153.244:26656,a98484ac9cb8235bd6a65cdf7648107e3d14dab4@116.202.231.58:36656,
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.okp4d/config/config.toml
```
Service file
```bash
sudo tee /etc/systemd/system/okp4.service > /dev/null <<EOF
[Unit]
Description=okp4
After=network-online.target

[Service]
User=$USER
ExecStart=$(which okp4d) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

Launch node and check logs
```bash
sudo systemctl daemon-reload && \
sudo systemctl enable okp4d && \
sudo systemctl restart okp4d && \
sudo journalctl -u okp4d -f -o cat
```

Wait until the node is fully synchronized.
```bash
okp4d status | jq
# The node is synchronized if the value in the "catching_up" line is false
```
Create a validator
```bash
okp4d tx staking create-validator \
--amount=1000000uknow \
--pubkey=$(okp4d tendermint show-validator) \
--moniker=$MONIKER \
--chain-id=$CHAIN \
--commission-rate="0.05" \
--commission-max-rate="0.20" \
--commission-max-change-rate="0.1" \
--min-self-delegation="1" \
--fees=100uknow \
--from=$WALLET \
--identity="" \
--website="" \
--details="" \
-y
```

Restart the node and check the logs
```bash
sudo systemctl restart okp4d  &&  sudo journalctl -u okp4d  -f -o cat
```
