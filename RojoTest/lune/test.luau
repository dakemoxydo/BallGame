--!strict
local suites = {
	require("../tests/ProfileData.spec"),
	require("../tests/ProfileData.bounds.spec"),
	require("../tests/Economy.spec"),
	require("../tests/Net.spec"),
}
local count, failed = 0, 0
for _, suite in suites do
	for name, test in suite do
		count += 1
		local ok, err = pcall(test)
		if ok then
			print("PASS " .. name)
		else
			failed += 1
			warn("FAIL " .. name .. ": " .. tostring(err))
		end
	end
end
assert(count > 0 and failed == 0, string.format("%d/%d tests failed", failed, count))
print(string.format("%d tests passed", count))
