--@name Set Sub Material B
--@author Rouing

-- Function is designed to take material 1 and set it to material 2 instead of using an index

function setSubMaterialB(ent, mat1, mat2)
    local mats = ent:getMaterials()
    for i = 1, #mats do
        if mats[i] == mat1 then
            ent:setSubMaterial(i-1,mat2)
        end
    end
end