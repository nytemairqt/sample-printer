-- lol
function print(text)
  reaper.ShowConsoleMsg(text)
end

-- Recursive file crawl
function GetAllFiles(folder)
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

function roll()
  return math.random() < 0.5
end

function trim(start, length)
  local scalar = .4
  local new_start = start + (length * (math.random() * scalar))
  local new_length = (start + length) - (length * (math.random() * scalar))
  return new_start, new_length
end

function pad(length, pad_amount)
  return length + pad_amount
end

function cleanup(track)
  while reaper.GetTrackNumMediaItems(track) > 0 do
    local item = reaper.GetTrackMediaItem(track, 0)
    if item then
      reaper.DeleteTrackMediaItem(track, item)
    end
  end
end

-- Main function
function Main()
  -- Hyperparameters
  local INPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/input"
  local OUTPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/output/tails"    
  local NUM_GENERATIONS = 500
  local SWAP_STEREO = true
  local REVERSE = true
  local RANDOM_TRIM = true
  local PAD_RIGHT = true 
  local PAD_AMOUNT = 8
  local FADE_IN = 0 -- in seconds 
  local FADE_OUT = 0.3
  local MAX_PITCH_SHIFT = -24

  -- Get Files & Create Output Dir
  local files = GetAllFiles(INPUT_FOLDER)
  if not reaper.file_exists(OUTPUT_FOLDER) then
    reaper.RecursiveCreateDirectory(OUTPUT_FOLDER, 0)
  end  
  reaper.ShowConsoleMsg("\nFound: " ..#files .. " files")
  if not files then 
    reaper.ShowMessageBox("Unable to load audio files.", "Error", 0)
    return 
  end 

  -- Loop & Process each file
  for i = 1, NUM_GENERATIONS, 1 do
    local seed = math.random(1, #files)
    local file = files[seed]
    reaper.ClearConsole()
    reaper.ShowConsoleMsg("\nGeneration: " ..i)
    reaper.Undo_BeginBlock()
    
    -- Import the audio file
    local track = reaper.GetTrack(0, 0) -- Get first track (where VST plugins are)
    if not track then
      track = reaper.InsertTrackAtIndex(0, true)
    end    

    reaper.ShowConsoleMsg("\nUsing file: " ..file)
    -- Insert media and get item
    reaper.InsertMedia(file, 0) -- Insert the media file
    local item = reaper.GetSelectedMediaItem(0, 0) -- Get the inserted item
    
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

        if PAD_RIGHT then 
          length = pad(length, PAD_AMOUNT)  
          reaper.GetSet_LoopTimeRange(true, false, start, length, false)
        end

        -- Generate output filename        
        local output_dir = string.format("%s/", OUTPUT_FOLDER)
        local output_file = string.format("processed_%s.wav", i)

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
  reaper.UpdateArrange()
  reaper.TrackList_AdjustWindows(false)
end

-- Execute the script
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)