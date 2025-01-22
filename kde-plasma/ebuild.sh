#!/bin/bash

# Para cada diretório
for dir in */; do
    if [ -d "$dir" ]; then
        echo "Processando diretório: $dir"
        cd "$dir"
        
        # Remove ebuilds 6.2.4
        rm -f *6.2.4.ebuild
        
        # Renomeia 6.2.5 para 6.2.90
        for file in *6.2.5.ebuild; do
            if [ -f "$file" ]; then
                newfile=$(echo "$file" | sed 's/6.2.5/6.2.90/')
                mv "$file" "$newfile"
                echo "Renomeado: $file -> $newfile"
            fi
        done
        
        # Roda ebuild manifest clean
        if ls *.ebuild 1> /dev/null 2>&1; then
            for ebuild in *.ebuild; do
                ebuild "$ebuild" manifest clean
            done
        fi
        
        cd ..
    fi
done