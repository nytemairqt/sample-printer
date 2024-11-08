-- Hyperparameters

INPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/01-process-raw-audio/input"
OUTPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/01-process-raw-audio/output"    
NUM_GENERATIONS = 200
SWAP_STEREO = true
REVERSE = true
RANDOM_TRIM = true
PAD_RIGHT = true 
PAD_AMOUNT = 8
RANDOMIZE_FX = true 
FADE_IN = 0
FADE_OUT = 0.3
MAX_PITCH_SHIFT = -24

-- Functions

function print(text)
  -- Prints to console.
  reaper.ShowConsoleMsg(text)
end

function GetAllFiles(folder)
  -- Recursive file search.
  local files = {}
  local function scanFolder(currentFolder)
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
  scanFolder(folder)
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

function trim(start, length)
  -- Trims a random start & end point, scaled by the offset scalar.
  local scalar = .4
  local new_start = start + (length * (math.random() * scalar))
  local new_length = (start + length) - (length * (math.random() * scalar))
  return new_start, new_length
end

function pad(length, pad_amount)
  -- Extends the length of the clip to the right.
  return length + pad_amount
end

function randomize_fx(track)
  -- Randomizes all FX on the selected track, skipping FX and parameters based on a dictionary.
  local fx_count = reaper.TrackFX_GetCount(track)
  for fx_idx = 0, fx_count - 1 do 
    local param_count = reaper.TrackFX_GetNumParams(track, fx_idx)
    local _, fx_name = reaper.TrackFX_GetFXName(track, fx_idx, "")
    local skip_names = {"VST3: OTT (Xfer Records)", "VST3: Morph EQ (Minimal)", "VST: Gullfoss (Soundtheory)", "VST: ReaEQ (Cockos)", "VST3: Transient Master (Native Instruments)", "VST: KClip Zero (Kazrog)", "VST3: Ozone 9 Elements (iZotope, Inc.)"}
    local skip_fx = false 
    for _, keyword in ipairs(skip_names) do 
      if fx_name == keyword then 
        print("\nSkipping: "..fx_name)
        skip_fx = true 
        break
      end 
    end 
    if not skip_fx then 
      print("\nFX: "..fx_name)
      for param_idx = 0, param_count - 1 do 
        local _, min, max, _ = reaper.TrackFX_GetParamEx(track, fx_idx, param_idx)
        local _, param_name = reaper.TrackFX_GetParamName(track, fx_idx, param_idx, "")
        local skip_keywords = {"bypass", "wet", "dry", "dry/wet", "mix", "enable", "on/off", "active", "power", "phase", "polarity", "routing", "midi", "input", "output", "gain", "drive", "makeup", "makeup_db"}
        local skip_param = false        
        param_name = param_name:lower()
        for _, keyword in ipairs(skip_keywords) do 
          if param_name:find(keyword) then 
            skip_param = true 
            break
          end 
        end        
        if not skip_param then           
          local val = min + (math.random() * max) 
          if param_name == "feedback" then 
            val = min + (math.random() * (max * 0.9))   
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

function Main()
  -- Initial Setup
  local track = reaper.GetTrack(0, 0)
  unsolo_tracks()  
  reaper.SetEditCurPos(0.0, true, false)
  reaper.SetOnlyTrackSelected(track)
  reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 2) 
  
  -- Get Files & Create Output Dir
  local files = GetAllFiles(INPUT_FOLDER)
  if not reaper.file_exists(OUTPUT_FOLDER) then
    reaper.RecursiveCreateDirectory(OUTPUT_FOLDER, 0)
  end  
  if not files then 
    reaper.ShowMessageBox("Unable to load audio files.", "Error", 0)
    return 
  end   

  -- Loop & Process each file
  for i = 1, NUM_GENERATIONS, 1 do
    reaper.ClearConsole()
    reaper.ShowConsoleMsg("\nGeneration: " ..i)
    reaper.Undo_BeginBlock()
    reaper.SetEditCurPos(0.0, true, false)

    if RANDOMIZE_FX then 
      randomize_fx(track)
    end 

    -- Import audio
    local seed = math.random(1, #files)
    local file = files[seed]
    reaper.InsertMedia(file, 0) 
    local item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)   
    if item then
      local take = reaper.GetActiveTake(item)
      if take then
        local start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        -- Swap L&R channels 
        reaper.SetMediaTrackInfo_Value(track, "D_WIDTH", 1)
        if SWAP_STEREO and roll() then
          reaper.ShowConsoleMsg("\nSwapping L&R channels.")
          reaper.SetMediaTrackInfo_Value(track, "D_WIDTH", -1)
        end

        -- Reverse Buffer
        if REVERSE and roll() then
          reaper.ShowConsoleMsg("\nReversing audio buffer.")
          reaper.Main_OnCommand(41051, 0) -- toggle take reverse
        end

        -- Apply Pitch Shift
        local pitch_shift = math.random() * MAX_PITCH_SHIFT
        reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch_shift)

        -- Trim Item
        reaper.GetSet_LoopTimeRange(true, false, start, start + length, false)
        if RANDOM_TRIM then 
          start, length = trim(start, length)
          reaper.GetSet_LoopTimeRange(true, false, start, length, false)
          reaper.Main_OnCommand(40508, 0) -- trim item to selected area  
        end      

        -- Pad Right Side
        if PAD_RIGHT then 
          length = pad(length, PAD_AMOUNT)  
          reaper.GetSet_LoopTimeRange(true, false, start, length, false)
        end

        -- Generate output filename        
        local output_dir = string.format("%s/", OUTPUT_FOLDER)
        local output_file = string.format("head_%s.wav", i)
        reaper.ShowConsoleMsg("\nOutput Path: " ..output_dir)
        reaper.ShowConsoleMsg("\nOutput Filename: " ..output_file)
        
        -- Set render settings
        local FADEIN_ENABLE <const> = 1<<9
        local FADEOUT_ENABLE <const> = 1<<10
        local FADEOUT = reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE', 0, false)
        local SHAPE_LINEAR <const> = 0
        reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 2, true) -- Time selection
        reaper.GetSetProjectInfo(0, "RENDER_SRATE", 96000, true) -- render sample rate
        reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", 2, true) -- Stereo
        reaper.GetSetProjectInfo(0, "RENDER_NORMALIZE", FADEOUT | FADEIN_ENABLE | FADEOUT_ENABLE, true)
        reaper.GetSetProjectInfo(0, "RENDER_FADEIN", FADE_IN, true)
        reaper.GetSetProjectInfo(0, "RENDER_FADEOUT", FADE_OUT, true)
        reaper.GetSetProjectInfo(0, 'RENDER_FADEINSHAPE',  SHAPE_LINEAR, true)
        reaper.GetSetProjectInfo(0, 'RENDER_FADEOUTSHAPE',  SHAPE_LINEAR, true)
        reaper.GetSetProjectInfo_String(0, "RENDER_FILE", output_dir, true)
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", output_file, true)
        
        -- Render
        --reaper.Main_OnCommand(41824, 0) -- Render project using last settings
        reaper.Main_OnCommand(42230, 0) -- Render project using last settings (and close dialog)
        
        -- Clean Up
        cleanup(track)
      end
    end   

    -- End undo block
    reaper.Undo_EndBlock("Process Audio File", -1)
  end
  
  -- Refresh UI
  unsolo_tracks()  
  reaper.UpdateArrange()
  reaper.TrackList_AdjustWindows(false)
end

-- Execute the script
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)