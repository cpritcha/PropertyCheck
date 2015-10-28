macro randtest(expr)
    :(@test begin
        srand(100)
        $expr
    end)
end
macro randshow(expr)
    :(begin
        srand(100)
        @show $expr
    end)
end

const signeds_0to10 = pc.signeds(0, 10)
const signeds_5to10 = pc.signeds(5, 10)
const floats_0to10 = pc.floats(0.0, 10.0)

const just0 = pc.just(0)
const just5 = pc.just(5)

const utf8strings_e0to127_l5to10 = pc.utf8strings(0, 127, signeds_5to10)

const vec_e0to10_l0     = pc.vectors(floats_0to10, just0)
const vec_e0to10_l5     = pc.vectors(signeds_0to10, just5)
const vec_e0to10_l5to10 = pc.vectors(signeds_0to10, signeds_5to10)

const dict_k0to10_v0to10_l0 = pc.dicts(signeds_0to10, signeds_0to10, just0)
const dict_k0to127_v0to10_l5to10 = pc.dicts(utf8strings_e0to127_l5to10, signeds_0to10, signeds_0to10)

const set_e0to10_l0 = pc.sets(signeds_0to10, just0)
const set_e0to127_l5 = pc.sets(utf8strings_e0to127_l5to10, just5)

const tuple_00 = pc.tuples(just0, just0)

# ----- Numbers -----

#@randshow pc.arbitrary(signeds_0to10)
@randtest pc.arbitrary(signeds_0to10) == 1
@test collect(pc.shrink(1, signeds_0to10)) == Any[]

#@randshow num2hex(pc.arbitrary(floats_0to10))
@randtest pc.arbitrary(floats_0to10) == hex2num("3ffe733681421eec")
@test collect(pc.shrink(5.0, floats_0to10)) == Any[]

# ----- Just -----

@test pc.arbitrary(just0) == 0
@test collect(pc.shrink(0, just0)) == []

@test pc.arbitrary(just5) == 5
@test collect(pc.shrink(0, just5)) == []

# ----- UTF8Strings -----

#@randshow pc.arbitrary(utf8strings_e0to127_l5to10)
@randtest pc.arbitrary(utf8strings_e0to127_l5to10) == "\0#A6Ix"

@test collect(pc.shrink("123456789", utf8strings_e0to127_l5to10)) == ["12345", "56789"]

# ----- Vectors -----

@test pc.arbitrary(vec_e0to10_l0) == Float64[]
@test collect(pc.shrink(Float64[], vec_e0to10_l0)) == []

#@randshow pc.arbitrary(vec_e0to10_l5)
@randtest pc.arbitrary(vec_e0to10_l5) == [1,1,9,10,2]
@test collect(pc.shrink([0,6,9,10,2], vec_e0to10_l5)) == []

@test collect(pc.shrink([0,3,6,9,10,2], vec_e0to10_l5to10)) == Vector[[0,3,6,9,10], [3,6,9,10,2]]

# ----- Dicts -----

@test pc.arbitrary(dict_k0to10_v0to10_l0) == Dict{Int64, Int64}()

#@randshow pc.arbitrary(dict_k0to127_v0to10_l5to10)
@randtest pc.arbitrary(dict_k0to127_v0to10_l5to10) == Dict("#A6Ix"=>0)

# ----- Sets -----

#@randshow pc.arbitrary(set_e0to10_l0)
@test pc.arbitrary(set_e0to10_l0) == Set{Int64}()

#@randshow pc.arbitrary(set_e0to127_l5)
@randtest pc.arbitrary(set_e0to127_l5) == Set(UTF8String["7\x120XfuxC&","#\0%\t_","\0#A6Ix","!}\x06*j\x17\x13&","V(j]\x7f"])

# ----- Tuples -----

@test pc.arbitrary(tuple_00) == (0,0)