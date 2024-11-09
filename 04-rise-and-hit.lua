-- Import
_, path = reaper.get_action_context()
folder_path = path:match('^.+[\\/]')
package.path = folder_path .. '?.lua;'
require "functions"

-- Hyperparameters
OUTPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/04-rise-and-hit/output"    
HEADS = "C:/Users/nytem/Documents/Waveloaf/_dev/04-rise-and-hit/input/01-heads"
KICKS = "C:/Users/nytem/Documents/Waveloaf/_dev/04-rise-and-hit/input/02-kicks"
BODIES = "C:/Users/nytem/Documents/Waveloaf/_dev/04-rise-and-hit/input/03-bodies"
TAILS = "C:/Users/nytem/Documents/Waveloaf/_dev/04-rise-and-hit/input/04-tails"
NUM_GENERATIONS = 5
RANDOMIZE_FX = true
RANDOMIZE_REVERB = true 
PAD_RIGHT = true 
PAD_AMOUNT = 3
FADE_IN = 0 -- in seconds 
FADE_OUT = 0.2

function Main()
  -- Initial Setup
  local group_track = reaper.GetTrack(0, 3)
  local head_track = reaper.GetTrack(0, 4)
  local kick_track = reaper.GetTrack(0, 5) 
  local kick_octave_track = reaper.GetTrack(0, 6)
  local body_track = reaper.GetTrack(0, 7) 
  local tail_track = reaper.GetTrack(0, 8)
  unsolo_tracks() 
  reaper.SetEditCurPos(0.0, false, false) -- reset cursor position

  -- Solo tracks in place 
  reaper.SetMediaTrackInfo_Value(group_track, "I_SOLO", 2) 
  reaper.SetMediaTrackInfo_Value(head_track, "I_SOLO", 2) 
  reaper.SetMediaTrackInfo_Value(kick_track, "I_SOLO", 2) 
  reaper.SetMediaTrackInfo_Value(kick_octave_track, "I_SOLO", 2) 
  reaper.SetMediaTrackInfo_Value(body_track, "I_SOLO", 2) 
  reaper.SetMediaTrackInfo_Value(tail_track, "I_SOLO", 2) 

  -- Get Files & Create Output Dir
  if not reaper.file_exists(OUTPUT_FOLDER) then
    reaper.RecursiveCreateDirectory(OUTPUT_FOLDER, 0)
  end  
  local head_files = get_files(HEADS)
  local kick_files = get_files(KICKS)
  local body_files = get_files(BODIES)
  local tail_files = get_files(TAILS)

  -- Loop & Process each file
  for i = 1, NUM_GENERATIONS, 1 do
    reaper.ClearConsole()
    reaper.ShowConsoleMsg("\nGeneration: " ..i)
    reaper.Undo_BeginBlock()
    reaper.SetEditCurPos(0.0, false, false) -- reset cursor position

    if RANDOMIZE_FX then 
      randomize_fx(head_track)
      randomize_fx(kick_track)
      randomize_fx(kick_octave_track)
      randomize_fx(body_track)
      randomize_fx(tail_track)
    end
    if RANDOMIZE_REVERB then 
      randomize_reverb(head_track)
      randomize_reverb(kick_track)
      randomize_reverb(kick_octave_track)
      randomize_reverb(body_track)
      randomize_reverb(tail_track)
    end

    local head_seed = math.random(1, #head_files)
    local kick_seed = math.random(1, #kick_files)
    local body_seed = math.random(1, #body_files)
    local tail_seed = math.random(1, #tail_files)    
  
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
    timeline_end = pad(timeline_end, PAD_AMOUNT)
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
    reaper.Main_OnCommand(42230, 0) -- Render project using last settings
    
    -- Clean Up
    cleanup(head_track)
    cleanup(kick_track)
    cleanup(kick_octave_track)
    cleanup(body_track)
    cleanup(tail_track)
        
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