function x = str2RegSpacedVector(str)
x = cellfun(@(x) str2double(x),strsplit(str,' '));
end
