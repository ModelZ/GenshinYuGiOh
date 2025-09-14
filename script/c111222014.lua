--My Brother's
--Scripted by You
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon fusion materials when Genshin Fusion monster leaves field
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_LEAVE_FIELD)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_series={0x700} --"Genshin" archetype

-- Store material info for multiple Fusion monsters leaving the field
local fusionMatGroups = {}

--Condition: check if any "Genshin" Fusion monster left by opponent's effect
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    fusionMatGroups={} -- reset each activation
    local trigger=false
    for tc in aux.Next(eg) do
        if tc:IsPreviousLocation(LOCATION_MZONE)
            and tc:IsType(TYPE_FUSION)
            and tc:IsSetCard(0x700)
            and tc:GetPreviousControler()==tp
            and (r&REASON_EFFECT)~=0
            and rp==1-tp then

            local mat=tc:GetMaterial()
            if mat and #mat>0 then
                table.insert(fusionMatGroups, mat)
                trigger=true
            end
        end
    end
    -- store all groups in effect
    if trigger then e:SetLabelObject(fusionMatGroups) end
    return trigger
end

--Target function: check if all materials can be Special Summoned
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local groups=e:GetLabelObject()
        if not groups or #groups==0 then return false end
        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        local total=0
        for _,mat in ipairs(groups) do
            local summonable=mat:Filter(function(c,e,tp)
                return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
            end,nil,e,tp)
            total=total+#summonable
        end
        return ft>0 and total>0
    end

    local groups=e:GetLabelObject()
    local count=0
    for _,mat in ipairs(groups) do
        count=count+#mat
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,count,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

--Operation: Special Summon all stored materials from all zones
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local groups=e:GetLabelObject()
    if not groups or #groups==0 then return end
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return end

    local toSummon=Group.CreateGroup()

    for _,mat in ipairs(groups) do
        for tc in aux.Next(mat) do
            if tc:IsCanBeSpecialSummoned(e,0,tp,false,false) then
                toSummon:AddCard(tc)
            else
                -- if original material is banished or in deck/grave/hand, try to find a copy
                local found=nil
                for loc in {LOCATION_HAND,LOCATION_DECK,LOCATION_GRAVE,LOCATION_REMOVED} do
                    local g=Duel.GetMatchingGroup(function(c) return c:GetCode()==tc:GetCode() and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,loc,0,nil)
                    if #g>0 then
                        found=g:GetFirst()
                        break
                    end
                end
                if found then toSummon:AddCard(found) end
            end
        end
    end

    if #toSummon>ft then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        toSummon=toSummon:Select(tp,ft,ft,nil)
    end

    if #toSummon>0 then
        Duel.SpecialSummon(toSummon,0,tp,tp,false,false,POS_FACEUP)
        -- shuffle deck if any summoned from deck
        local deckSummoned=toSummon:Filter(Card.IsLocation,nil,LOCATION_DECK)
        if #deckSummoned>0 then
            Duel.ShuffleDeck(tp)
        end
    end
end
