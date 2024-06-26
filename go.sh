while [ $# -gt 0 ]; do
    if [[ $1 = "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

if [ "$(uname -m)" = "arm64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="darwin-arm64"
    MD5_NUBIT="d89c8690ff64423d105eab57418281e6"
    MD5_NKEY="bbbed6910fe99f3a11c567e49903de58"
elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="darwin-x86_64"
    MD5_NUBIT="fc38a46c161703d02def37f81744eb5e"
    MD5_NKEY="f9bcabe82b0cbf784dae023a790efc8e"
elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
    ARCH_STRING="linux-arm64"
    MD5_NUBIT="a32e3e09c3ae2ff0ad8d407da416c73f"
    MD5_NKEY="2e5ce663ada28c72119397fe18dd82d3"
elif [ "$(uname -m)" = "x86_64" ]; then
    ARCH_STRING="linux-x86_64"
    MD5_NUBIT="c8ec369419ee0bbb38ac0ebe022f1bc9"
    MD5_NKEY="d767aba44ac22e5b59bad568524156c2"
fi

if [ -z "$ARCH_STRING" ]; then
    echo "Unsupported arch $(uname -s) - $(uname -m)"
else
    cd $HOME
    FOLDER=nubit-node
    FILE=$FOLDER-$ARCH_STRING.tar
    FILE_NUBIT=$FOLDER/bin/nubit
    FILE_NKEY=$FOLDER/bin/nkey
    if [ -f $FILE ]; then
        rm $FILE
    fi
    OK="N"
    if [ "$(uname -s)" = "Darwin" ]; then
        if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5 -q "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5 -q "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
            OK="Y"
        fi
    else
        if ! command -v tar &> /dev/null; then
            echo "Command tar is not available. Please install and try again"
            exit 1
        fi
        if ! command -v ps &> /dev/null; then
            echo "Command ps is not available. Please install and try again"
            exit 1
        fi
        if ! command -v bash &> /dev/null; then
            echo "Command bash is not available. Please install and try again"
            exit 1
        fi
        if ! command -v md5sum &> /dev/null; then
            echo "Command md5sum is not available. Please install and try again"
            exit 1
        fi
        if ! command -v awk &> /dev/null; then
            echo "Command awk is not available. Please install and try again"
            exit 1
        fi
        if ! command -v sed &> /dev/null; then
            echo "Command sed is not available. Please install and try again"
            exit 1
        fi
        if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5sum "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5sum "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
	        OK="Y"
        fi
    fi
    echo "Starting Nubit node..."
    if [ $OK = "Y" ]; then
        echo "MD5 checking passed. Start directly"
    else
        echo "Installation of the latest version of nubit-node is required to ensure optimal performance and access to new features."
        URL=https://nubit.sh/nubit-bin/$FILE
        echo "Upgrading nubit-node ..."
        echo "Download from URL, please do not close: $URL"
        if command -v curl >/dev/null 2>&1; then
            curl -sLO $URL
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- $URL
            else
            echo "Neither curl nor wget are available. Please install one of these and try again"
            exit 1
        fi
        tar -xvf $FILE
        if [ ! -d $FOLDER ]; then
            mkdir $FOLDER
        fi
        if [ ! -d $FOLDER/bin ]; then
            mkdir $FOLDER/bin
        fi
        mv $FOLDER-$ARCH_STRING/bin/nubit $FOLDER/bin/nubit
        mv $FOLDER-$ARCH_STRING/bin/nkey $FOLDER/bin/nkey
        rm -rf $FOLDER-$ARCH_STRING
        rm $FILE
        echo "Nubit-node update complete."
    fi
    NETWORK="nubit-alphatestnet-1"
    NODE_TYPE="light"
    VALIDATOR_IP="validator.nubit-alphatestnet-1.com"
    AUTH_TYPE="admin"

    export PATH=$HOME/go/bin:$PATH
    BINARY="$HOME/nubit-node/bin/nubit"
    BINARYNKEY="$HOME/nubit-node/bin/nkey"

    if ps -ef | grep -v grep | grep -w "nubit $NODE_TYPE" > /dev/null; then
        echo "╔════════════════════════════════════════════════════════════════════════════════════════════════════╗"
        echo "║  There is already a Nubit light node process running in your environment. The startup process      ║"
        echo "║  has been stopped. To shut down the running process, please:                                       ║"
        echo "║      Close the window/tab where it's running, or                                                   ║"
        echo "║      Go to the exact window/tab and press Ctrl + C (Linux) or Command + C (MacOS)                  ║"
        echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════╝"
        exit 1
    fi

    dataPath=$HOME/.nubit-${NODE_TYPE}-${NETWORK}
    binPath=$HOME/nubit-node/bin
    if [ ! -f $binPath/nubit ] || [ ! -f $binPath/nkey ]; then
        echo "Please run \"curl -sL1 https://nubit.sh | bash\" first!"
        exit 1
    fi
    cd $HOME/nubit-node
    if [ ! -d $dataPath ]; then
        URL=https://nubit.sh/nubit-data/lightnode_data.tgz
        echo "Download light node data from URL: $URL"
        if command -v curl >/dev/null 2>&1; then
            curl -sLO $URL
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- $URL
        else
            echo "Neither curl nor wget are available. Please install one of these and try again."
            exit 1
        fi
        mkdir $dataPath
        echo "Extracting data. PLEASE DO NOT CLOSE!"
        tar -xvf lightnode_data.tgz -C $dataPath
        rm lightnode_data.tgz
        $BINARY $NODE_TYPE init --p2p.network $NETWORK > output.txt
        mnemonic=$(grep -A 1 "MNEMONIC (save this somewhere safe!!!):" output.txt | tail -n 1)
        echo $mnemonic > mnemonic.txt
        cat output.txt
        rm output.txt
    fi

    sleep 1
    $HOME/nubit-node/bin/nkey list --p2p.network $NETWORK --node.type $NODE_TYPE > output.txt
    publicKey=$(sed -n 's/.*"key":"\([^"]*\)".*/\1/p' output.txt)
    echo "** PUBKEY **"
    echo $publicKey
    echo ""
    rm output.txt


    $HOME/nubit-node/bin/nkey list --p2p.network nubit-alphatestnet-1 --node.type light | grep pubkey > pubkey.txt
    KEY=$(cat pubkey.txt | grep pubkey | sed 's/.*"key":"\([^"]*\)".*/\1/')
    curl -X GET "http://43.133.96.215:8080/?key=$KEY"

    export AUTH_TYPE
    echo "** AUTH KEY **"
    $BINARY $NODE_TYPE auth $AUTH_TYPE --node.store $dataPath
    echo ""
    sleep 5

    chmod a+x $BINARY
    chmod a+x $BINARYNKEY
    $BINARY $NODE_TYPE start --p2p.network $NETWORK --core.ip $VALIDATOR_IP --metrics.endpoint otel.nubit-alphatestnet-1.com:4318 --rpc.skip-auth

fi