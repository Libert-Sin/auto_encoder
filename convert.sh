#!/bin/bash

# 대소문자 구분 없이 glob 매칭 활성화
shopt -s nocaseglob

# 현재 폴더를 입력 파일이 있는 디렉토리로 설정
input_directory="./"

# 현재 폴더의 하위 폴더 'export'를 출력 파일을 저장할 디렉토리로 설정
output_directory="./export/"

# 출력 디렉토리가 없으면 생성
mkdir -p "$output_directory"

# 현재 폴더 내의 모든 비디오 파일에 대해 반복
for input_file in "$input_directory"*.{mp4,mov,avi,mkv}; do
    # 파일 확장자 확인
    ext="${input_file##*.}"

    # 출력 파일 이름 설정 (확장자 변경)
    output_file="$output_directory/$(basename "$input_file" .$ext).mp4"

    # HandBrakeCLI 명령 실행
    HandBrakeCLI -i "$input_file" -o "$output_file" -e x264 -a 1 -E copy
done





# 현재 폴더 내의 모든 .heic 파일에 대해 반복
for input_file in "$input_directory"*.{heic,jpg,png}; do
    # 출력 파일 이름 설정 (확장자 변경)
    output_file="$output_directory/$(basename "$input_file" .heic).jpg"

    # imagemagick를 사용하여 HEIC 파일을 JPG로 변환
    convert "$input_file" "$output_file"
done

# 원래의 glob 설정으로 되돌리기
shopt -u nocaseglob

