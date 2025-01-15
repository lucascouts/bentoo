#!/bin/bash

# Verifica se está em um ambiente Gentoo/portage
if ! command -v ebuild &> /dev/null; then
    echo "Erro: comando 'ebuild' não encontrado. Este script requer um ambiente Gentoo."
    exit 1
fi

# Contador para diretórios processados
processed=0
failed=0

# Para cada diretório no diretório atual
for dir in */; do
    if [ -d "$dir" ]; then
        echo "Processando diretório: $dir"
        
        # Entra no diretório
        cd "$dir"
        
        # Verifica se existe algum arquivo .ebuild
        if ls *.ebuild 1> /dev/null 2>&1; then
            # Executa o comando ebuild
            if ebuild *.ebuild manifest clean; then
                echo "✓ Comando executado com sucesso em: $dir"
                ((processed++))
            else
                echo "✗ Falha ao executar comando em: $dir"
                ((failed++))
            fi
        else
            echo "- Nenhum arquivo .ebuild encontrado em: $dir"
        fi
        
        # Volta para o diretório pai
        cd ..
        echo "----------------------------------------"
    fi
done

# Relatório final
echo "Relatório Final:"
echo "Diretórios processados com sucesso: $processed"
echo "Diretórios com falha: $failed"
echo "Processo concluído!"