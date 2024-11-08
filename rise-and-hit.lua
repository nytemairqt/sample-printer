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
  local OUTPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/output/rise-and-hit"    

  local HEADS = "C:/Users/nytem/Documents/Waveloaf/_dev/input-rise-and-hit/01-heads"
  local KICKS = "C:/Users/nytem/Documents/Waveloaf/_dev/input-rise-and-hit/02-kicks"
  local BODIES = "C:/Users/nytem/Documents/Waveloaf/_dev/input-rise-and-hit/03-bodies"
  local TAILS = "C:/Users/nytem/Documents/Waveloaf/_dev/input-rise-and-hit/04-tails"

  local NUM_GENERATIONS = 1
  local PAD_RIGHT = true 
  local PAD_AMOUNT = 1
  local FADE_IN = 0 -- in seconds 
  local FADE_OUT = 0

  reaper.SetEditCurPos(0.0, false, false) -- reset cursor position

  -- Check if we have enough tracks
  if reaper.CountTracks(project) < 5 then
      reaper.ShowMessageBox("Project needs at least 5 tracks!", "Error", 0)
      return
  end

  local head_track = reaper.GetTrack(0, 2) -- kick track
  local kick_track = reaper.GetTrack(0, 3) 
  local kick_octave_track = reaper.GetTrack(0, 4)
  local body_track = reaper.GetTrack(0, 5) 
  local tail_track = reaper.GetTrack(0, 6) 

  -- Get Files & Create Output Dir
  if not reaper.file_exists(OUTPUT_FOLDER) then
    reaper.RecursiveCreateDirectory(OUTPUT_FOLDER, 0)
  end  

  local head_files = GetAllFiles(HEADS)
  local kick_files = GetAllFiles(KICKS)
  local body_files = GetAllFiles(BODIES)
  local tail_files = GetAllFiles(TAILS)

  -- Loop & Process each file
  for i = 1, NUM_GENERATIONS, 1 do
    local head_seed = math.random(1, #head_files)
    local kick_seed = math.random(1, #kick_files)
    local body_seed = math.random(1, #body_files)
    local tail_seed = math.random(1, #tail_files)

    reaper.ClearConsole()
    reaper.ShowConsoleMsg("\nGeneration: " ..i)
    reaper.Undo_BeginBlock()
  
    local head = head_files[head_seed]
    local kick = kick_files[kick_seed]
    local body = body_files[body_seed]
    local tail = tail_files[tail_seed]
    
    -- Head
    reaper.SetOnlyTrackSelected(head_track)
    reaper.InsertMedia(head, 0)
    local head_item = reaper.GetTrackMediaItem(head_track, reaper.CountTrackMediaItems(head_track)-1)
    local head_start = reaper.GetMediaItemInfo_Value(head_item, "D_POSITION")
    local head_length = reaper.GetMediaItemInfo_Value(head_item, "D_LENGTH")
    local head_take = reaper.GetActiveTake(head_item)
    reaper.Main_OnCommand(41051, 0) -- toggle take reverse

    -- Kick
    local kick_transient_position = head_start + head_length
    reaper.SetEditCurPos(kick_transient_position, false, false)
    reaper.SetOnlyTrackSelected(kick_track)
    reaper.InsertMedia(kick, 0)
    local kick_item = reaper.GetTrackMediaItem(kick_track, reaper.CountTrackMediaItems(kick_track)-1)

    -- Kick Octave
    reaper.SetEditCurPos(kick_transient_position, false, false)
    reaper.SetOnlyTrackSelected(kick_octave_track)
    reaper.InsertMedia(kick, 0)
    local kick_octave_item = reaper.GetTrackMediaItem(kick_octave_track, reaper.CountTrackMediaItems(kick_octave_track)-1)
    kick_octave_take = reaper.GetActiveTake(kick_octave_item)
    reaper.SetMediaItemTakeInfo_Value(kick_octave_take, "D_PITCH", -12) -- apply octave shift

    -- Body
    reaper.SetEditCurPos(kick_transient_position, false, false)
    reaper.SetOnlyTrackSelected(body_track)
    reaper.InsertMedia(body, 0)
    local body_item = reaper.GetTrackMediaItem(body_track, reaper.CountTrackMediaItems(body_track)-1)

    -- Tail 
    reaper.SetEditCurPos(kick_transient_position, false, false)
    reaper.SetOnlyTrackSelected(tail_track)
    reaper.InsertMedia(tail, 0)
    local tail_item = reaper.GetTrackMediaItem(tail_track, reaper.CountTrackMediaItems(tail_track)-1)

    --local kick_take = reaper.GetActiveTake(kick_item)
    --local body_take = reaper.GetActiveTake(body_item)
    --local tail_take = reaper.GetActiveTake(tail_item)

    -- Set start & end points
    local tail_start = reaper.GetMediaItemInfo_Value(tail_item, "D_POSITION")
    local tail_length = reaper.GetMediaItemInfo_Value(tail_item, "D_LENGTH")

    local timeline_end = find_end()
    reaper.GetSet_LoopTimeRange(true, false, head_start, timeline_end, false)

    -- Trim Body to Tail End & Fade 
    reaper.SetMediaItemInfo_Value(body_item, "D_LENGTH", tail_length * .2)
    local body_fade = reaper.GetMediaItemInfo_Value(body_item, "D_LENGTH")
    reaper.SetMediaItemInfo_Value(body_item, "D_FADEOUTLEN", body_fade)

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
    --reaper.Main_OnCommand(42230, 0) -- Render project using last settings
    
    -- Clean Up
    --cleanup(head_track)
    --cleanup(kick_track)
    --cleanup(body_track)
    --cleanup(tail_track)
    
    
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