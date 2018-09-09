#/bin/sh
if [ -d love ]; then
    if [ -f love/tj.love ]; then
        rm love/tj.love
    fi
else
    mkdir love
fi

zip -9 -r love/tj.love game/*
