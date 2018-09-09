#/bin/sh
./zip.sh
if [ -f bin/tj.exe ]; then
    rm bin/tj.exe
fi

cat love.exe love/tj.love > bin/tj.exe
cd bin
zip -9 -r ../tj.zip .
