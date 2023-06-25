#!/usr/bin/env bash
. ~/.bashrc
if [ ! $AGORIC_NODENAME ]; then
	read -p "Enter node name: " AGORIC_NODENAME
	echo 'export AGORIC_NODENAME='$AGORIC_NODENAME >> $HOME/.bash_profile
	. ~/.bash_profile
fi

echo 'Your node name: ' $AGORIC_NODENAME
sleep 2
sudo dpkg --configure -a
sudo apt update
sudo apt install curl -y < "/dev/null"
sleep 1

# curl https://deb.nodesource.com/setup_14.x | sudo bash
# curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
# echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
# sudo apt upgrade -y < "/dev/null"
# sudo apt install nodejs=14.* yarn build-essential jq git -y < "/dev/null"
# sleep 1

sudo apt update
curl https://deb.nodesource.com/setup_16.x | sudo bash
sudo apt install -y nodejs gcc g++ make < "/dev/null"
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install yarn
sleep 1

# sudo rm -rf /usr/local/go
# curl https://dl.google.com/go/go1.15.7.linux-amd64.tar.gz | sudo tar -C/usr/local -zxvf -
# cat <<'EOF' >> $HOME/.bash_profile
# export GOROOT=/usr/local/go
# export GOPATH=$HOME/go
# export GO111MODULE=on
# export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
# EOF
# . $HOME/.bash_profile
# cp /usr/local/go/bin/go /usr/bin
# go version

cd $HOME
wget -c -O go1.17.1.linux-amd64.tar.gz https://golang.org/dl/go1.17.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz && sudo rm go1.17.1.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
sudo cp $(which go) /usr/local/bin
go version

# export GIT_BRANCH=agorictest-17
export GIT_BRANCH=agoricdev-7
cd $HOME
git clone https://github.com/Agoric/agoric-sdk -b $GIT_BRANCH
(cd agoric-sdk && yarn && yarn build)
. $HOME/.bash_profile
(cd $HOME/agoric-sdk/packages/cosmic-swingset && make)
cd $HOME/agoric-sdk

# curl https://testnet.agoric.net/network-config > chain.json
curl https://devnet.agoric.net/network-config > chain.json
chainName=`jq -r .chainName < chain.json`
echo $chainName

agd init --chain-id $chainName $AGORIC_NODENAME
# curl https://testnet.agoric.net/genesis.json > $HOME/.agoric/config/genesis.json 
curl https://devnet.agoric.net/genesis.json > $HOME/.agoric/config/genesis.json 
agd unsafe-reset-all
peers=$(jq '.peers | join(",")' < chain.json)
seeds=$(jq '.seeds | join(",")' < chain.json)
echo $peers
echo $seeds
sed -i.bak 's/^log_level/# log_level/' $HOME/.agoric/config/config.toml
sed -i.bak -e "s/^seeds *=.*/seeds = $seeds/; s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.agoric/config/config.toml
sudo tee <<EOF >/dev/null /etc/systemd/system/agd.service
[Unit]
Description=Agoric Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which agd) start --log_level=warn
Restart=on-failure
RestartSec=3
LimitNOFILE=10000
Environment="OTEL_EXPORTER_PROMETHEUS_PORT="$OTEL_EXPORTER_PROMETHEUS_PORT
#Environment="SLOGFILE=$HOME/$AGORIC_NODENAME-agorictest17-chain.slog"

[Install]
WantedBy=multi-user.target
EOF
echo 'export OTEL_EXPORTER_PROMETHEUS_PORT=9464' >> $HOME/.bash_profile
. ~/.bash_profile
sed -i '/\[telemetry\]/{:a;n;/enabled/s/false/true/;Ta};/\[api\]/{:a;n;/enable/s/false/true/;Ta;}' $HOME/.agoric/config/app.toml
sed -i "s/prometheus-retention-time = 0/prometheus-retention-time = 60/g" $HOME/.agoric/config/app.toml
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025ubld\"/;" $HOME/.agoric/config/app.toml
sed -i "s/prometheus = false/prometheus = true/g" $HOME/.agoric/config/config.toml
sudo systemctl enable agd
sudo systemctl daemon-reload
sudo systemctl start agd
echo 'Metrics URL: http://'$(curl -s ifconfig.me)':9464/metrics'
echo 'Metric link will work after sync'
echo 'Node status:'$(sudo service agd status | grep active)
