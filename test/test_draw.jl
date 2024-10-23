using Crayons


line = ["a","b","c"]

for (i,x) in enumerate(line)
    if x == "b"
        line[i] = string(Crayon(foreground=:red), x)
    else
        #line[i] = string(Crayon(foreground=:white), x)
    end
end
println(line)
for x in line
    print(x)
    print(string(Crayon(foreground=:white)))
end
println(string(Crayon(foreground=:white)))
println("back to normal")
println("back to normal2")
