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

function pad(length, pad_amount)
  return length + pad_amount
end

function trim(start, length)
  local scalar = .4
  local new_start = start + (length * (math.random() * scalar))
  local new_length = (start + length) - (length * (math.random() * scalar))
  return new_start, new_length
end

function cleanup(track)
  while reaper.GetTrackNumMediaItems(track) > 0 do
    local item = reaper.GetTrackMediaItem(track, 0)
    if item then
      reaper.DeleteTrackMediaItem(track, item)
    end
  end
end

function find_end()
    local last_position = 0
    local num_items = reaper.CountMediaItems(0)

    for i = 0, num_items - 1 do
        local item = reaper.GetMediaItem(0, i)
        local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        -- Update last_position if the current item end is further
        if item_end > last_position then
            last_position = item_end
        end
    end

  return last_position
end

-- Main function
function Main()
  -- Hyperparameters
  local INPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/tail-from-transient/input"
  local OUTPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/tail-from-transient/output"    

  local NUM_GENERATIONS = 5
  local MAX_LENGTH = 1.5  
  local FADE_IN = 0
  local FADE_OUT = 0.5

  reaper.SetEditCurPos(0.0, true, false) -- reset cursor position
  
  local track = reaper.GetTrack(0, 8)

  -- Get Files & Create Output Dir
  if not reaper.file_exists(OUTPUT_FOLDER) then
    reaper.RecursiveCreateDirectory(OUTPUT_FOLDER, 0)
  end  

  local files = GetAllFiles(INPUT_FOLDER)

  -- Loop & Process each file
  for i = 1, NUM_GENERATIONS, 1 do
    reaper.ClearConsole()
    reaper.ShowConsoleMsg("\nGeneration: " ..i)
    reaper.Undo_BeginBlock()
    reaper.SetEditCurPos(0.0, true, false) -- reset cursor position
    
    local seed = math.random(1, #files)   
    local transient = files[seed]
    
    -- Head
    reaper.SetOnlyTrackSelected(track)
    reaper.InsertMedia(transient, 0)
    local transient_item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)
    local transient_start = reaper.GetMediaItemInfo_Value(transient_item, "D_POSITION")
    local transient_length = reaper.GetMediaItemInfo_Value(transient_item, "D_LENGTH")
    local transient_take = reaper.GetActiveTake(transient_item)    
    local pitch_shift = math.random() * -12

    -- Trim
    start, length = trim(transient_start, transient_length)
    reaper.GetSet_LoopTimeRange(true, false, start, length, false)
    reaper.Main_OnCommand(40508, 0) -- trim item to selected area  

    -- Fade
    reaper.SetMediaItemTakeInfo_Value(transient_take, "D_PITCH", pitch_shift)
    reaper.SetMediaItemInfo_Value(transient_item, "D_FADEOUTLEN", length)
    reaper.SetMediaItemInfo_Value(transient_item, "C_FADEOUTSHAPE", 4) -- exponential

    -- Start & End Points
    reaper.GetSet_LoopTimeRange(true, false, transient_start, MAX_LENGTH, false)
    
    -- Generate output filename        
    local output_dir = string.format("%s/", OUTPUT_FOLDER)
    local output_file = string.format("tail_%s.wav", i)

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
    reaper.Main_OnCommand(42230, 0) -- Render project using last settings
    
    -- Clean Up
    cleanup(track)       
    
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