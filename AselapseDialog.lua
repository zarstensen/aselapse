function AselapseDialog()
    dialog = Dialog{ title = "Aselapse" }
    
end

-- local dlg = Dialog { title = "Hellow World Window!!!" }
-- local log_count = 0

-- dlg:slider {
--     id = "varName1",
--     label = "Percent",
--     min = 0,
--     max = 100,
--     value = 50,
-- }

-- dlg:color {
--     id = "varName2",
--     label = "Color",
--     color = Color(255, 128, 64, 32),
-- }

-- dlg:combobox {
--     id = "varName3",
--     label = "Options: ",
--     option = "Num 1",
--     options = {
--         "Num 1",
--         "Num 2",
--         "Num 3",
--         "Num 4",
--         "Num 5",
--     },
-- }

-- dlg:button {
--     id = "logOptions",
--     text = "LOG",
--     onclick = function()
--         local data = dlg.data

--         print(dump(data))

--         log_count = log_count + 1

--         dlg:modify{
--             id = "varName1",
--             label = "Percent",
--             min = 0,
--             max = log_count * 100,
--             value = log_count * 500,
--         }

--         print(log_count)

--     end
-- }

-- dlg:show { wait = false }

