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

-- Main function
function Main()
  -- Hyperparameters
  local sourceFolder = "C:/Users/nytem/Desktop/taiko"
  local outputFolder = "C:/Users/nytem/Desktop/taiko/output"    
  local NUM_GENERATIONS = 20
  local FADE_IN = 0 -- in seconds 
  local FADE_OUT = 0
  local MAX_PITCH_SHIFT = -24

  -- Get Files & Create Output Dir
  local files = GetAllFiles(sourceFolder)
  if not reaper.file_exists(outputFolder) then
    reaper.RecursiveCreateDirectory(outputFolder, 0)
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
        -- Get item properties
        local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        -- Create random section (between 1 and 4 seconds)
        local new_len = math.random() * 3 + 1
        if new_len > item_len then new_len = item_len end
        local start_pos = math.random() * (item_len - new_len)
        
        -- Trim item
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", start_pos)
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
        
        -- Apply Pitch Shift
        local pitch_shift = math.random() * MAX_PITCH_SHIFT
        reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch_shift)
        
        -- Select item timerange for render
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local item_end = item_pos + item_length

        reaper.ShowConsoleMsg("\nAudio Start: " ..item_pos)
        reaper.ShowConsoleMsg("\nAudio End: " ..item_end)
        -- add hyperparameter for reverb tail padding 
        -- item_length += TAIL_PAD
        reaper.GetSet_LoopTimeRange(true, false, item_pos, item_pos + item_length, false)
        
        -- Generate output filename        
        local output_dir = string.format("%s/", outputFolder)
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
        
        -- Clean up
        reaper.DeleteTrackMediaItem(track, item)
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