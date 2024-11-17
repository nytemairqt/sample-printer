function print(text)
  -- Prints to console.
  reaper.ShowConsoleMsg(text)
end

function get_files(folder)
  -- Recursive file search.
  local files = {}
  local function scan_folder(currentFolder)
    local cmd
    if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
      -- Get files in current folder
      cmd = 'dir /b /s "' .. currentFolder .. '\\*.wav"'
    else
      cmd = 'find "' .. currentFolder .. '" -name "*.wav"'
    end    
    local p = io.popen(cmd)
    for file in p:lines() do
      table.insert(files, file)  -- On Windows with /s flag, file paths are already absolute
    end
    p:close()
  end  
  scan_folder(folder)
  return files
end

function unsolo_tracks()
  -- Unsolos all tracks.
  local num_tracks = reaper.CountTracks(0)
  for i = 0, num_tracks - 1 do
      local track = reaper.GetTrack(0, i)
      reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
  end
end

function roll()
  -- Coin Flip
  return math.random() < 0.5
end

function trim(start, length, scalar)
  -- Trims a random start & end point, scaled by the offset scalar.
  local new_start = start + (length * (math.random() * scalar))
  local new_length = (start + length) - (length * (math.random() * scalar))
  return new_start, new_length
end

function pad(length, pad_amount)
  -- Extends the length of the clip to the right.
  return length + pad_amount
end

function randomize_fx(track, name, randomize_feedback)  
  local fx_count = reaper.TrackFX_GetCount(track)
  local skip_keywords = {"bypass", "wet", "dry", "dry/wet", "mix", "enable", "enabled", "on/off", "active", "power", "phase", "polarity", "routing", "midi", "input", "output", "gain", "drive", "makeup", "makeup_db"}
  local skip_feedback = {"feedback", "decay", "repeats", "echo", "length", "size", "echoes"}
  for fx_idx = 0, fx_count - 1 do     
    local _, fx_name = reaper.TrackFX_GetFXName(track, fx_idx, "")
    local param_count = reaper.TrackFX_GetNumParams(track, fx_idx)
    if fx_name == name then 
      for param_idx = 0, param_count - 1 do 
        local _, min, max, _ = reaper.TrackFX_GetParamEx(track, fx_idx, param_idx)
        local _, param_name = reaper.TrackFX_GetParamName(track, fx_idx, param_idx, "")      
        local skip_param = false        
        param_name = param_name:lower()
        for _, keyword in ipairs(skip_keywords) do 
          if param_name:find(keyword) then 
            skip_param = true 
            break
          end 
        end   
        if not randomize_feedback then 
          for _, keyword in ipairs(skip_feedback) do 
            if param_name:find(keyword) then 
              skip_param = true 
              break
            end 
          end   
        end 
        if not skip_param then 
          local val = min + (math.random() * max) 
          for _, keyword in ipairs(skip_feedback) do 
            if param_name == keyword then 
              val = min + (math.random() * (max * 0.7)) 
              break
            end 
          end             
          reaper.TrackFX_SetParamNormalized(track, fx_idx, param_idx, val)
        end       
      end 
    end 
  end
end

function cleanup(track)
  -- Deletes all media items on the track.
  while reaper.GetTrackNumMediaItems(track) > 0 do
    local item = reaper.GetTrackMediaItem(track, 0)
    if item then
      reaper.DeleteTrackMediaItem(track, item)
    end
  end
end

function find_end()
  -- Moves the playhead cursor to the end of the media clips.
  local last_position = 0
  local num_items = reaper.CountMediaItems(0)
  for i = 0, num_items - 1 do
    local item = reaper.GetMediaItem(0, i)
    local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")    
    if item_end > last_position then
        last_position = item_end
    end
  end
  return last_position
end