function link_extend_data(data)
  log(string.format("-----\n%s", inspect(data)))
  data.extend(data)
end
