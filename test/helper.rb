module TestHelper
  def try_cases(*cases)
    index = nil
    begin
      cases.each_with_index do |test_case, i|
        index = i
        yield(*test_case)
      end
    rescue Exception => e
      new_e = e.class.new("Case #{index} failed.\n" + e.message)
      new_e.set_backtrace(e.backtrace)
      raise new_e
    end                                                       
  end                                                         
end                                                              

