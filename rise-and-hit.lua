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

-- Main function
function Main()
  -- Hyperparameters
  local INPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/input"
  local OUTPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/output/05-generated"    
  local HEADS = "C:/Users/nytem/Documents/Waveloaf/_dev/output/01-heads"
  local KICKS = "C:/Users/nytem/Documents/Waveloaf/_dev/output/02-kicks"
  local BODIES = "C:/Users/nytem/Documents/Waveloaf/_dev/output/03-bodies"
  local TAILS = "C:/Users/nytem/Documents/Waveloaf/_dev/output/04-tails"
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

  local head_track = reaper.GetTrack(0, 1) -- kick track
  local kick_track = reaper.GetTrack(0, 2) 
  local body_track = reaper.GetTrack(0, 3) 
  local tail_track = reaper.GetTrack(0, 4) 

  -- Get Files & Create Output Dir
  --local files = GetAllFiles(INPUT_FOLDER)
  if not reaper.file_exists(OUTPUT_FOLDER) then
    reaper.RecursiveCreateDirectory(OUTPUT_FOLDER, 0)
  end  
  --reaper.ShowConsoleMsg("\nFound: " ..#files .. " files")
  --if not files then 
    --reaper.ShowMessageBox("Unable to load audio files.", "Error", 0)
    --return 
  --end 

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
    local kick_item = reaper.GetSelectedMediaItem(0, 0) -- Get the inserted item
    reaper.SetEditCurPos(kick_transient_position, false, false)

    -- Body
    reaper.SetOnlyTrackSelected(body_track)
    reaper.InsertMedia(body, 0)
    local body_item = reaper.GetSelectedMediaItem(0, 0) -- Get the inserted item
    reaper.SetEditCurPos(kick_transient_position, false, false)

    -- Tail 
    reaper.SetOnlyTrackSelected(tail_track)
    reaper.InsertMedia(tail, 0)
    local tail_item = reaper.GetSelectedMediaItem(0, 0) -- Get the inserted item      

    --local kick_take = reaper.GetActiveTake(kick_item)
    --local body_take = reaper.GetActiveTake(body_item)
    --local tail_take = reaper.GetActiveTake(tail_item)

    -- Set start & end points
    local tail_start = reaper.GetMediaItemInfo_Value(tail_item, "D_POSITION")
    local tail_length = reaper.GetMediaItemInfo_Value(tail_item, "D_LENGTH")

    reaper.GetSet_LoopTimeRange(true, false, head_start, tail_start + tail_length, false)
    --reaper.Main_OnCommand(40508, 0) -- trim item, do i need this?

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