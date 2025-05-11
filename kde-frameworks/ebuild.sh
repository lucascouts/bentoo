#!/bin/bash

# Para cada diretório
for dir in */; do
    if [ -d "$dir" ]; then
        echo "Processando diretório: $dir"
        cd "$dir"
        
        # Remove ebuilds 'very old'
        rm -f *-5.*.ebuild
        
        # Renomeia 'old' para 'new'
        for file in *6.13.*.ebuild; do
            if [ -f "$file" ]; then
                newfile=$(echo "$file" | sed 's/6.13.*/6.14.0/')
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