class Youtube
  attr_accessor :video_id, :embed_url, :embed_code, :url, :provider, :title, :description, :keywords,
                :duration, :date, :width, :height,
                :thumbnail_small, :thumbnail_large,
                :view_count,
                :openURI_options

  def initialize(url, options = {}, get_params = '')
    @openURI_options = options
		@get_params = get_params
    video_id_for(url)
    get_info unless @video_id == url || @video_id.nil? || @video_id.empty?
  end

  def regex
    /youtu(.be)?(be.com)?.*(?:\/|v=)([\w-]+)/
  end

  def video_id_for(url)
    url.gsub(regex) do
      @video_id = $3
    end
  end

private

  def get_info
    begin
      doc = Hpricot(open("http://gdata.youtube.com/feeds/api/videos/#{@video_id}", @openURI_options))
      @provider         = "YouTube"
      @url              = "http://www.youtube.com/watch?v=#{@video_id}"
      @embed_url        = "http://www.youtube.com/embed/#{@video_id}#{param_string}"
      @embed_code       = "<iframe src=\"#{@embed_url}\" frameborder=\"0\" allowfullscreen=\"allowfullscreen\"></iframe>"
      @title            = doc.search("media:title").inner_text#{param_stringo
      @description      = doc.search("media:description").inner_text
      @keywords         = doc.search("media:keywords").inner_text
      @duration         = doc.search("yt:duration").first[:seconds].to_i
      @date             = Time.parse(doc.search("published").inner_text, Time.now.utc)
      @thumbnail_small  = doc.search("media:thumbnail").min { |a,b| a[:height].to_i * a[:width].to_i <=> b[:height].to_i * b[:width].to_i }[:url]
      @thumbnail_large  = doc.search("media:thumbnail").max { |a,b| a[:height].to_i * a[:width].to_i <=> b[:height].to_i * b[:width].to_i }[:url]
      # when your video still has no view, yt:statistics is not returned by Youtube
      # see: https://github.com/thibaudgg/video_info/issues#issue/2
      if doc.search("yt:statistics").first
        @view_count     = doc.search("yt:statistics").first[:viewcount].to_i
      else
        @view_count     = 0
      end
    rescue
      nil
    end
  end

	def param_string
		@get_params.empty? ? '' : '?' + @get_params	
	end

end
