#/bin/sh
if [ -d love ]; then
    if [ -f love/tj.love ]; then
        rm love/tj.love
    fi
else
    mkdir love
fi

cd game
zip -9 -r ../love/tj.love .
