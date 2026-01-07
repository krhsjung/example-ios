#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_localization.py
.xcstrings 파일들을 파싱하여 String+Localization.swift 파일을 자동 생성합니다.

사용법:
    python3 generate_localization.py [프로젝트_경로]

Xcode Build Phase에서 자동 실행:
    cd "$SRCROOT/example"
    python3 Core/Localization/generate_localization.py
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path


def to_camel_case(snake_str):
    """
    snake_case를 camelCase로 변환
    예: error_invalid_input -> errorInvalidInput
    """
    components = snake_str.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


def sanitize_key(key, prefix_to_remove=None):
    """
    키를 Swift 변수명으로 사용 가능하도록 변환
    """
    if prefix_to_remove and key.startswith(prefix_to_remove):
        key = key[len(prefix_to_remove):]
    return to_camel_case(key)


def parse_xcstrings_file(file_path):
    """
    .xcstrings 파일을 파싱하여 키 목록 반환
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        strings = data.get('strings', {})
        return sorted(strings.keys())
    except Exception as e:
        print(f"⚠️  Error parsing {file_path}: {e}")
        return []


def group_keys_by_prefix(keys):
    """
    키들을 prefix별로 그룹화
    예: login_title, login_subtitle -> login: [title, subtitle]
    """
    groups = {}
    for key in keys:
        parts = key.split('_', 1)
        if len(parts) > 1:
            prefix = parts[0]
            if prefix not in groups:
                groups[prefix] = []
            groups[prefix].append(key)
        else:
            if 'other' not in groups:
                groups['other'] = []
            groups['other'].append(key)
    return groups


def generate_enum_cases(table_name, keys, use_grouping=False):
    """
    Enum case들을 생성
    """
    if not keys:
        return '        // No keys found'

    cases = []
    seen_var_names = set()

    if use_grouping:
        groups = group_keys_by_prefix(keys)
        for group_name, group_keys in sorted(groups.items()):
            if len(groups) > 1:
                cases.append(f'        // {group_name.title()}')
            for key in group_keys:
                var_name = sanitize_key(key)
                original_var_name = var_name
                counter = 1
                while var_name in seen_var_names:
                    var_name = f"{original_var_name}{counter}"
                    counter += 1
                seen_var_names.add(var_name)
                cases.append(f'        static let {var_name} = String.{table_name.lower()}("{key}")')
            if len(groups) > 1:
                cases.append('')
    else:
        for key in keys:
            var_name = sanitize_key(key)
            original_var_name = var_name
            counter = 1
            while var_name in seen_var_names:
                var_name = f"{original_var_name}{counter}"
                counter += 1
            seen_var_names.add(var_name)
            cases.append(f'        static let {var_name} = String.{table_name.lower()}("{key}")')

    result = '\n'.join(cases)
    if result.endswith('\n'):
        result = result[:-1]
    return result


def generate_swift_file(tables_data):
    """
    Swift 파일 내용 생성
    tables_data: dict of {table_name: keys_list}
    """
    current_date = datetime.now().strftime('%m/%d/%y')

    # String extension 메서드 생성
    extension_methods = []
    for table_name in sorted(tables_data.keys()):
        # 기본 메서드 (파라미터 없음)
        method = f'''    /// {table_name}.xcstrings에서 문자열 가져오기
    /// - Parameter key: 다국어 키
    /// - Returns: 현재 언어로 번역된 문자열
    static func {table_name.lower()}(_ key: String) -> String {{
        String(localized: String.LocalizationValue(key), table: "{table_name}")
    }}'''
        extension_methods.append(method)
        
        # 파라미터를 받는 메서드 추가 (모든 테이블에 대해)
        param_method = f'''    
    /// {table_name}.xcstrings에서 문자열 가져오기 (파라미터 포함)
    /// - Parameters:
    ///   - key: 다국어 키
    ///   - arguments: 문자열에 삽입할 값들
    /// - Returns: 현재 언어로 번역되고 파라미터가 삽입된 문자열
    static func {table_name.lower()}(_ key: String, _ arguments: CVarArg...) -> String {{
        let format = String(localized: String.LocalizationValue(key), table: "{table_name}")
        return String(format: format, arguments: arguments)
    }}'''
        extension_methods.append(param_method)

    # Enum 생성
    enum_sections = []
    for table_name in sorted(tables_data.keys()):
        keys = tables_data[table_name]
        cases = generate_enum_cases(table_name, keys, use_grouping=(table_name == 'Auth'))
        enum_section = f'''    // MARK: - {table_name} Keys ({len(keys)} keys)
    enum {table_name} {{
{cases}
    }}'''
        enum_sections.append(enum_section)

    total_keys = sum(len(keys) for keys in tables_data.values())

    swift_content = f'''//
//  String+Localization.swift
//  example
//
//  Path: Core/Localization/String+Localization.swift
//  Auto-generated on {current_date}
//  ⚠️ DO NOT EDIT MANUALLY - This file is auto-generated by generate_localization.py
//

import Foundation

// MARK: - String Localization Extension
extension String {{
{chr(10).join(extension_methods)}
}}

// MARK: - Localized String Keys
/// 타입 안전한 다국어 키를 위한 네임스페이스
/// Total: {total_keys} keys
enum Localized {{

{chr(10).join(f'{section}{chr(10)}' for section in enum_sections)}}}
'''

    return swift_content


def main():
    """
    메인 실행 함수
    """
    # 프로젝트 경로 확인
    if len(sys.argv) > 1:
        project_path = Path(sys.argv[1])
    else:
        # 스크립트 위치 기준으로 프로젝트 경로 찾기
        script_path = Path(__file__).resolve()
        project_path = script_path.parent.parent.parent  # Core/Extensions -> example

    print(f"🔍 Scanning project at: {project_path}")

    # Localization 폴더 경로
    localization_path = project_path / "Resources" / "Localization"

    if not localization_path.exists():
        print(f"❌ Localization folder not found at: {localization_path}")
        sys.exit(1)

    # .xcstrings 파일들 자동 탐색
    xcstrings_files = list(localization_path.glob("*.xcstrings"))

    if not xcstrings_files:
        print(f"❌ No .xcstrings files found in: {localization_path}")
        sys.exit(1)

    print(f"📁 Found {len(xcstrings_files)} xcstrings file(s)")

    # 각 파일 파싱
    tables_data = {}
    for file_path in xcstrings_files:
        table_name = file_path.stem  # 파일명에서 확장자 제거
        keys = parse_xcstrings_file(file_path)
        tables_data[table_name] = keys
        print(f"   📝 {table_name}: {len(keys)} keys")

    # Swift 파일 생성
    swift_content = generate_swift_file(tables_data)

    # 파일 저장 (Core/Localization 폴더에)
    output_file = project_path / "Core" / "Localization" / "String+Localization.swift"

    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(swift_content)

        total_keys = sum(len(keys) for keys in tables_data.values())
        print(f"✅ Generated: {output_file}")
        print(f"   Total: {total_keys} localized strings")
    except Exception as e:
        print(f"❌ Error writing file: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
