-- Import
_, path = reaper.get_action_context()
folder_path = path:match('^.+[\\/]')
package.path = folder_path .. '?.lua;'
require "functions"

-- Hyperparameters

INPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/01-process-raw-audio/input"
OUTPUT_FOLDER = "C:/Users/nytem/Documents/Waveloaf/_dev/01-process-raw-audio/output"    
NUM_GENERATIONS = 200
RANDOMIZE_FX = true
RANDOMIZE_REVERB = true
SWAP_STEREO = true
REVERSE = true
RANDOM_TRIM = true
PAD_RIGHT = true 
PAD_AMOUNT = 8
FADE_IN = 0
FADE_OUT = 0.3
MAX_PITCH_SHIFT = -24

function Main()
  -- Initial Setup
  local track = reaper.GetTrack(0, 0)
  unsolo_tracks()  
  reaper.SetEditCurPos(0.0, true, false)
  reaper.SetOnlyTrackSelected(track)
  reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 2) 
  
  -- Get Files & Create Output Dir
  local files = get_files(INPUT_FOLDER)
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
    if RANDOMIZE_REVERB then 
      randomize_reverb(track)
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
          start, length = trim(start, length, .4)
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