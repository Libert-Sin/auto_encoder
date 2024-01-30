require 'fileutils'
require 'tempfile'
require 'date'

# FFMPEG 명령을 실행하고 로그를 파싱하는 함수
def encode_video(ffmpeg_cmd, total_duration, log_file)
  start_time = Time.now
  pid = spawn("#{ffmpeg_cmd} 2> #{log_file.path}")
  log_file.rewind  # 로그 파일 포인터를 처음으로 되돌림
  while Process.waitpid(pid, Process::WNOHANG).nil?
    sleep 1
    log_file.each do |line|
      if line =~ /time=\s*(\d+:\d+:\d+\.\d+)/
        current_time = DateTime.parse($1).to_time
        start_time_of_video = DateTime.parse("00:00:00.00").to_time
        elapsed_video_time = (current_time - start_time_of_video).to_f
        percent_complete = (elapsed_video_time / total_duration * 100).round(2)
        progress_str = sprintf("%.2f%%", percent_complete)
        elapsed_time = Time.now - start_time
        remaining_time = elapsed_video_time > 0 ? elapsed_time / elapsed_video_time * (total_duration - elapsed_video_time) : 0
        complete_time = Time.now + remaining_time

        elapsed_time_str = Time.at(elapsed_time).utc.strftime("%H:%M:%S")
        remaining_time_str = Time.at(remaining_time).utc.strftime("%H:%M:%S")
        complete_time_str = complete_time.strftime("%H:%M:%S")
        printf("진행률: %-10s 경과시간: %-10s 남은시간: %-10s 완료예상시간: %-10s\n",
                  progress_str, elapsed_time_str, remaining_time_str, complete_time_str)
      end
    end
  end
end




# 이미지 파일 변환 함수
def convert_image(input_file, output_file)
  system("convert '#{input_file}' -quality 100 '#{output_file}'")
end

# 인자에 따라 FFMPEG 명령 및 출력 파일 형식을 설정하는 함수
def ffmpeg_command_and_output_file(input_file, output_directory, option)
  ext = File.extname(input_file)
  case option
  when '-dnxhd'
    output_file = "#{output_directory}/#{File.basename(input_file, ext)}.mov"
    command = "ffmpeg -hwaccel auto -i '#{input_file}' -vf 'format=yuv422p10le' -c:v dnxhd -profile:v dnxhr_hqx -c:a pcm_s24le -f mov '#{output_file}'"
  when '-h264'
    output_file = "#{output_directory}/#{File.basename(input_file, ext)}.mp4"
    command = "ffmpeg -hwaccel auto -i '#{input_file}' -c:v libx264 -crf 16 -preset veryslow '#{output_file}'"
  when '-h265'
    output_file = "#{output_directory}/#{File.basename(input_file, ext)}.mp4"
    command = "ffmpeg -hwaccel auto -i '#{input_file}' -c:v libx265 -preset veryslow -crf 16 -pix_fmt yuv420p10le '#{output_file}'"
  else
    return [nil, nil]
  end
  [command, output_file]
end

# 메인 로직
input_directory = "./"
output_directory = "./export/"
FileUtils.mkdir_p(output_directory)
option = ARGV[0] # 첫 번째 커맨드 라인 인자

input_file_directory = File.dirname(input_directory)
log_file = Tempfile.new('ffmpeg_log', input_file_directory)

if option.nil?
  puts "option : -dnxhd / -h264 / -h265"
else
  Dir.glob("#{input_directory}*.{mp4,mov,avi,mkv,mxf,rsv}", File::FNM_CASEFOLD).each do |input_file|
    ffprobe_duration_cmd = "ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 '#{input_file}'"
    total_duration = `#{ffprobe_duration_cmd}`.to_f # 영상의 총 길이를 초 단위로 구함

    ffmpeg_cmd, output_file = ffmpeg_command_and_output_file(input_file, output_directory, option)
    next if ffmpeg_cmd.nil?
    encode_video(ffmpeg_cmd, total_duration, log_file) # total_duration을 전달
  end
end


# 이미지 파일 처리
Dir.glob("#{input_directory}*.{heic,jpg,png}", File::FNM_CASEFOLD).each do |input_file|
  ext = File.extname(input_file)
  output_file = "#{output_directory}/#{File.basename(input_file, ext)}.jpg"
  convert_image(input_file, output_file)
end

# 로그 파일 삭제
log_file.close
log_file.unlink
