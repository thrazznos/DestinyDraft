function get_DestinySet
{
    param([string]$uri = "http://swdestinydb.com/set/AW")
 
    $test2 = Invoke-WebRequest $uri -Method GET
 
    $tablesHTML = @($test2.ParsedHtml.getElementsByTagName("TABLE"))
 
    $datatable = New-Object System.Data.DataTable
    $datatable.Columns.AddRange(@(
        (
            "Name",
            "Faction",
            "Color",
            "Cost",
            "Health",
            "Type",
            "Rarity",
            "Dice1",
            "Dice2",
            "Dice3",
            "Dice4",
            "Dice5",
            "Dice6",
            "Set")
            ))
 
    $data = $test2.ParsedHtml.getElementsByTagName("tr") #| ParsedHTML
 
 
    forEach($datum in $data){
        #Find all items with TableRow Tag
        if($datum.tagname -eq "TR"){
            $dataRow = $datatable.NewRow()
            #Get children of Table Rows (contains TD items)
            $cells = $datum.children
            $ListItems = @()
       
            #Grab all table data cells
            forEach($child in $cells){
                if($child.tagName -eq "td"){
                    #$thisRow += $child.innerText
                    Write-Output $child.innerText
                    #Add item to list
                    $ListItems += $child.innerText
                }
            }
 
            #put items 1-6 + last into datarow (Leave out the dice sides)
            $dataRow.Name = $ListItems[0]
            $dataRow.Faction = $ListItems[1]
            $dataRow.Color = $ListItems[2]
            $dataRow.Cost = $ListItems[3]
            $dataRow.Health = $ListItems[4]
            $dataRow.Type = $ListItems[5]
            $dataRow.Rarity = $ListItems[6]
 
            $dataRow.Set = $ListItems[-1]
       
            $dataRow.Dice1 = $ListItems[7]
 
            if ($ListItems[7] -ne ' ')
            {
 
                $dataRow.Dice2 = $ListItems[8]
                $dataRow.Dice3 = $ListItems[9]
                $dataRow.Dice4 = $ListItems[10]
                $dataRow.Dice5 = $ListItems[11]
                $dataRow.Dice6 = $ListItems[12]
            }
 
            Write-Debug $dataRow
 
 
            $datatable.Rows.Add($dataRow)
        }
    }
    
    #$datatable |ogv
 
    return $datatable
}

function offer_card
{
    param(
        $playerNumber,
        $draftedBatch
    )

    Write-Host ("Player " + $playerNumber + " what card do you want?")
    $playerInput = Read-Host

    if($draftedBatch.GetEnumerator() | Where-Object {$_.Value -eq $playerInput} )
    { Write-Host ("That card is taken") 
    }

    return 

}

function output_results
{
    param(
    $DraftComplete,
    $numPlayers
    )

    for($i=1;$i -le $numPlayers; $i++)
    {
        Write-Host ("--------------------------------------------------------")
        Write-Host ("Cards selected by Player: " + $i)
        $draftedCards.GetEnumerator() | Where-Object {$_.Value -eq $i} |ForEach-Object Name
        #$var.Name | ogv
    }
}


<#
--------------------------------------
Funciton: Run_Draft
 
Takes a dataset of cards, breaks it down into a list of cards, displays the options
to the players and outputs their card lists afterward
 
--------------------------------------
#>
function run_ReflectiveBatch_draft
{
    param(
        $Cards,
        $NumPlayers,
        $num_drafts
    )
 
    $cardlist = @()
 
    foreach($Card in $Cards)
    {
        $cardlist += $Card.Name
    }
 
    #Randomize the cards in the list
    $DraftDeck = $cardList | Sort-Object {Get-Random}
 
    Write-Verbose ("Cardlist has " + $cardlist.Count + " cards")
    Write-Verbose ("Shuffledlist has " + $DraftDeck.Count + " cards")

    $cardsInBatch = ($NumPlayers * 2) + 1
 
    $draftedCards = @{}

    $PlayerOffset = 0   #Used to rotate who is first player ambivalent of iterations

    #Display the cards in groups
    #2 cards per player + 1 per batch
    for ($i=0; $i -lt ($num_drafts); $i++)
    {
        Write-Host ("Starting batch " + ($i + 1) + " of " + $num_drafts)
        Write-Host ("Player " + ($PlayerOffset + 1) + " is start")
        Write-Host "================================="

        #Set the batch iterators (ex 0-4 for 2 players, next iteration 5-9)
        $start = $i * $cardsInBatch
        $end = ($i + 1) * $cardsInBatch - 1
        $draftedBatch = @{}

        #Display the batch of cards
        #Print each card with Index prefix
        for ($j=1; $j -le $cardsInBatch;$j++)
        {Write-Host($j.ToString() + ". " + $DraftDeck[$start + $j])}


        #------------------------------------Individual Draft Loop------------------------------------
        #Loop goes through deck in chunks, drafting small numbers from each batch then moving on to next
        for ($j=0; $j -lt ($cardsInBatch - 1); $j++)
        {
            #If on first pass (divide current iterator by half of the total)
            if($j -lt $NumPlayers)
            {
                $playerIterator = (($j + $PlayerOffset) % $NumPlayers) + 1
                Write-Host ("Player " + $playerIterator + " what card do you want?")
                $playerInput = Read-Host


                if($draftedBatch.GetEnumerator() | Where-Object {$_.Name -eq $DraftDeck[$start + $playerInput]} )
                { Write-Host ("That card is taken") 
                }

                else
                {
                    Write-Host("You took " + $DraftDeck[$start + $playerInput])
                    $key = $DraftDeck[$start + $playerInput]
                    $value = $playerIterator
                 $draftedBatch.Add($key, $value)
                }
            }

            #else on second half, then do players in reverse order
            else
            {
                $baseiterator = ($j % $NumPlayers) + 1                                             # 1, 2, 3, 4,    2, 3, 4, 1

                $playerIterator = ((($NumPlayers * 2) - 1) - $j + $PlayerOffset) % $NumPlayers + 1 # 4, 3, 2, 1,    1, 4, 3, 2
                #1, 2, 3, 4, 4, 3, 2, 1
                #2, 3, 4, 1, 1, 4, 3, 2

                Write-Host ("Player " + ($playerIterator)+ " choose a card")
                $playerInput = Read-Host

                if($draftedBatch.GetEnumerator() | Where-Object {$_.Name -eq $DraftDeck[$start + $playerInput]} )
                { Write-Host ("That card is taken") 
                }

                else
                {
                    $key = $DraftDeck[$start + $playerInput]
                    $value = $playerIterator
                 $draftedBatch.Add($key, $value)
                }

            }
        }
        #----------------------------------------------------------------------------------------------
 
        #Add the drafted cards to the big pile of drafted cards
        $draftedCards = $draftedCards + $draftedBatch

        #update playeroffset (cycle 0-Numplayers)
        $playerOffset = ($PlayerOffset + 1) % $NumPlayers


        #Output the results
        #$draftedCards.GetEnumerator() | sort -Property Value
    }
    
    Write-Verbose ("End Draft " + ($i + 1))


    output_results -DraftComplete $draftedCards -numPlayers $NumPlayers
 
    #show (Players x2 + 1) number of cards
    #Offer the cards for players to draft in forward then reverse order
    #(Ex P1, P2, P3, P3, P2, P1)
    #Flag any leftover cards as discarded
 
 
    #write-debug $cardlist
}
 1
#Pull Awakenings Set
Write-Verbose "Retrieving Sets"
$awakenings = get_DestinySet

$DraftSet = $awakenings
#======================Other Sets included and merged here=====================
#$SpiritOfRebellion = get_DestinySet https://swdestinydb.com/set/SoR
#$DraftSet[0].Table.Merge($SpiritOfRebellion[0].Table)

#$EmpireAtWar = get_DestinySet https://swdestinydb.com/set/EaW
#$DraftSet[0].Table.Merge($EmpireAtWar[0].Table)

#$SetList = $awakenings + $SpiritOfRebellion + $EmpireAtWar + $TwoPlayerGame
#$DraftSet[0].Table.Merge($TwoPlayerGame[0].Table)

#==============================================================================
 
#Filter out all dice cards and battlefields
Write-Verbose "Filtering Set" #TODO: Could describe types of cards being filtered out, make the filtering more functional too
$Draftables = $DraftSet | Where-Object {($_.Type -ne "Battlefield" ) -and ($_.Dice1 -eq " ")}
#$SpiritOfRebellion = get_DestinySet
 
Write-Verbose "Starting Draft sequence"
run_ReflectiveBatch_draft -Cards $Draftables -NumPlayers 2 -num_drafts 30
 
 
#$SpiritOfRebellion = get_DestinySet https://swdestinydb.com/set/SoR
#$EmpireAtWar = get_DestinySet https://swdestinydb.com/set/EaW
#$TwoPlayerGame = get_DestinySet https://swdestinydb.com/set/TPG
