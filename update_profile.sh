#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
README_FILE="${ROOT_DIR}/README.md"

FOCOS=(
  "aprofundando meus estudos em backend, logica de programacao e organizacao de APIs"
  "refinando projetos da faculdade para ficarem mais consistentes e apresentaveis"
  "estudando persistencia, Git e boas praticas de desenvolvimento"
  "tentando escrever codigo mais simples, legivel e facil de manter"
  "explorando recomendacao, automacao e estrutura cliente-servidor"
)

RECADOS=(
  "seguindo na ideia de aprender construindo"
  "mais preocupado em entender bem a base do que em pular etapa"
  "evoluindo um projeto por vez, sem pular etapa"
  "tentando transformar estudo em pratica sempre que da"
  "mantendo o perfil atualizado conforme os projetos avancam"
)

pick_random() {
  local -n values_ref=$1
  local index=$((RANDOM % ${#values_ref[@]}))
  printf '%s' "${values_ref[$index]}"
}

if [[ ! -f "${README_FILE}" ]]; then
  echo "README.md nao encontrado em ${ROOT_DIR}."
  exit 1
fi

if ! git -C "${ROOT_DIR}" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Nenhum repositorio Git encontrado em ${ROOT_DIR}."
  exit 1
fi

REPO_ROOT="$(git -C "${ROOT_DIR}" rev-parse --show-toplevel)"
if [[ "${REPO_ROOT}" != "${ROOT_DIR}" ]]; then
  echo "Este script foi feito para rodar na raiz do repositorio do perfil."
  echo "Coloque README.md e update_profile.sh direto no repo do seu perfil antes de executar."
  exit 1
fi

foco_atual="$(pick_random FOCOS)"
recado_atual="$(pick_random RECADOS)"
atualizado_em="$(date '+%d/%m/%Y %H:%M')"

dynamic_block="$(cat <<EOF
- Foco atual: ${foco_atual}
- Atualizado em: ${atualizado_em}
- Recado: ${recado_atual}
EOF
)"

temp_file="$(mktemp)"

awk -v block="${dynamic_block}" '
  BEGIN {
    start_marker = "<!-- profile-status:start -->"
    end_marker = "<!-- profile-status:end -->"
    inside_block = 0
    replaced = 0
  }
  $0 == start_marker {
    print
    print block
    inside_block = 1
    replaced = 1
    next
  }
  $0 == end_marker {
    inside_block = 0
    print
    next
  }
  !inside_block { print }
  END {
    if (!replaced) {
      exit 2
    }
  }
' "${README_FILE}" > "${temp_file}" || {
  rm -f "${temp_file}"
  echo "Nao foi possivel localizar os marcadores de bloco dinamico no README.md."
  exit 1
}

if cmp -s "${README_FILE}" "${temp_file}"; then
  rm -f "${temp_file}"
  echo "Nenhuma alteracao detectada no README."
  exit 0
fi

mv "${temp_file}" "${README_FILE}"

if git -C "${ROOT_DIR}" diff --quiet -- README.md; then
  echo "README atualizado, mas sem diferenca rastreada pelo Git."
  exit 0
fi

git -C "${ROOT_DIR}" add README.md
git -C "${ROOT_DIR}" commit -m "docs: atualiza status do perfil"

if [[ "${1:-}" == "--push" ]]; then
  git -C "${ROOT_DIR}" push origin main
  echo "Perfil atualizado e enviado para o GitHub."
  exit 0
fi

echo "Perfil atualizado e commitado localmente."
echo "Use './update_profile.sh --push' para ja enviar ao GitHub."
