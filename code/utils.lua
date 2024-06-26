local utils = {}

utils.extend = function(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
end

utils.increaseKey = function(t, k, v)
	if t[k] == nil then
		t[k] = v
	else
		t[k] = t[k] + v
	end
end

utils.listToSet = function(l)
	-- Convert {a, b, c} to {a=true, b=true, c=true} so that we can check membership faster.
	local result = {}
	for _,v in ipairs(l) do
		result[v] = true
	end
	return result
end

return utils