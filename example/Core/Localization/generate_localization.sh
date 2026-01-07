#!/bin/bash
#
# generate_localization.sh
# .xcstrings 파일들을 파싱하여 String+Localization.swift 파일을 자동 생성합니다.
#
# Xcode Build Phase에서 실행하려면:
# 1. Target 선택 -> Build Phases
# 2. '+' 버튼 -> New Run Script Phase
# 3. 이 스크립트를 추가하고 "Compile Sources" 전에 실행되도록 드래그
#

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "${BLUE}🔍 Generating String+Localization.swift...${NC}"

# 프로젝트 루트 경로
PROJECT_DIR="${SRCROOT}"

# Python 스크립트 경로
SCRIPT_PATH="${PROJECT_DIR}/example/Core/Localization/generate_localization.py"

# Python 스크립트가 있는지 확인
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "${RED}❌ Error: generate_localization.py not found at ${SCRIPT_PATH}${NC}"
    echo "${YELLOW}   Please add generate_localization.py to example/Core/Localization/${NC}"
    exit 1
fi

# Python으로 스크립트 실행
python3 "$SCRIPT_PATH" "${PROJECT_DIR}/example"

# 결과 확인
if [ $? -eq 0 ]; then
    echo "${GREEN}✅ String+Localization.swift generated successfully${NC}"
else
    echo "${RED}❌ Failed to generate String+Localization.swift${NC}"
    exit 1
fi
