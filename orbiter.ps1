Add-Type -Path '.\engine.dll'

$engine = New-Object engine.Functions 

# you can run $engine | Get-Member to help with intelissense in vscode

# make your code here :]

#$engine.EnableAudioDevice() #need to enable this to be enable to load sounds
$w = 600
$h = 600

$pi = 3.14159265
$TAU = $pi * 2

$engine.CreateWindow($w,$h,"Orbiter")

#[Raylib_cs.Sound]$sound = $engine.LoadSoundFromFile("assets\sounds\sfx.wav")
$corPreto = $engine.GetNewColor(0,0,0,255)
$corBranco = $engine.GetNewColor(255,255,255,255)

$jogador = $engine.GetNewBall2D($engine.GetNewVector2(0,0),10,$engine.GetNewColor(255,255,255,255))

$angle = 0

[System.Collections.ArrayList] $bolas = @()
[System.Collections.ArrayList] $inimigos = @()
[System.Collections.ArrayList] $particulas = @()

function Add-ParticulaDano { param ([System.Numerics.Vector2]$pos,[Raylib_cs.Color]$color)
    $null = $particulas.Add(
        @{
            shape = $engine.GetNewBall2D($pos,5,$color)
            ttl = 1
        }
    )
}

function Add-Enemy { 
    $null = $inimigos.Add(
        @{
            shape = $engine.GetNewBall2D($engine.GetNewVector2(((0,$w)|Get-Random),((0,$h)|Get-Random)),10,($bolas | Get-Random).cor)
            vel = ((3..6)|Get-Random)
            alive = $true
        }
    )
}

function Add-Bola {
    $null = $bolas.Add(
        $engine.GetNewBall2D($engine.GetNewVector2(0,0),10,$engine.GetNewColor(((0..255)|Get-Random),((0..255)|Get-Random),((0..255)|Get-Random),255))
    )    
}

$wave = 0
$tempoProSpawn = 1
$tempoPraNovaBola = 30

$vidas = 2

Add-Bola

while(!$engine.MouseLeftPressed())
{
    $engine.DrawFrame();
    $engine.ClearFrameBackground()
    $engine.DrawText("Move your mouse and avoid being hit.`nYou can kill enemies by hitting them with `nsome of your orbit ball of the same color of the enemy`nClick to start",20,10,0)
    $engine.ClearFrame();
}

while(!$engine.IsAskingToCloseWindow()) {
    Start-Sleep -Milliseconds 16
    $angle += 6
    $tempoProSpawn -= $engine.DeltaTime() # $engine.DeltaTime() = 1 segundo
    $tempoPraNovaBola -= $engine.DeltaTime()

    $engine.DrawFrame();

    if($tempoProSpawn -le 0)
    {
        $tempoProSpawn = 1
        $wave++
        Add-Enemy
    }
    if($tempoPraNovaBola -le 0)
    {
        $tempoPraNovaBola = 30
        Add-Bola
    }
    # if([Raylib_cs.Raylib]::GetMouseWheelMove() -gt 0)
    # {
    #     Add-Bola
    # }

    if($inimigos.Count -gt 0)
    {
        for ($i = 0; $i -lt $inimigos.Count; $i++) {

            if($inimigos[$i].alive)
            {
                $angleToTarget = [Raylib_cs.Raymath]::Vector2Angle($inimigos[$i].shape.position,$jogador.position)

                $rot = (( $angleToTarget/360)*$TAU)
    
                $dir = $engine.AngleToNormalizedVector($rot) * $inimigos[$i].vel
                $inimigos[$i].shape.Move($dir.x,$dir.y)
                $inimigos[$i].shape.Draw()
                $inimigos[$i].vel += ($engine.DeltaTime()/5)
                for ($x = 0; $x -lt $bolas.Count; $x++) {
                    if($bolas[$x].IsCollidingWithBall2D($inimigos[$i].shape) -and ($bolas[$x].cor -eq $inimigos[$i].shape.cor ))
                    {
                        $inimigos[$i].alive = $false
                        Add-ParticulaDano -pos $inimigos[$i].shape.position -color $inimigos[$i].shape.cor
                    }
                }
                if($jogador.IsCollidingWithBall2D($inimigos[$i].shape))
                {
                    $inimigos[$i].alive = $false
                    Add-ParticulaDano -pos $inimigos[$i].shape.position -color $jogador.cor
                    $vidas--
                }
            }
        }
        for ($i = 0; $i -lt $inimigos.Count; $i++) {
            if(!$inimigos[$i].alive)
            {
                $inimigos.RemoveAt($i)
            }
        }
    }
    
    if($angle -gt 360) {$angle = 0}

    
    if($bolas.Count -gt 0)
    {
        for ($i = 0; $i -lt $bolas.Count; $i++) {
            $degreeDestaBola = (360/$bolas.Count*($i+1)) + $angle
            $rot = ($degreeDestaBola/360) * $TAU
            $pos = $engine.AngleToNormalizedVector($rot) * 70
            $bolas[$i].position = $jogador.position + $pos
            $bolas[$i].Draw()
        }
    }

    if($particulas.Count -gt 0)
    {
        for ($i = 0; $i -lt $particulas.Count; $i++) {
            $particulas[$i].ttl -= $engine.DeltaTime()
            $particulas[$i].shape.radius++
            $particulas[$i].shape.DrawLine()
        }
        for ($i = 0; $i -lt $particulas.Count; $i++) {
            if($particulas[$i].ttl -le 0)
            {
                $particulas.RemoveAt($i)
            }
        }
    }

    if($vidas -eq 2)
    {
        $jogador.position = $engine.GetNewVector2($engine.MousePosX(),$engine.MousePosY())
        $jogador.Draw()
    }
    elseif($vidas -eq 1)
    {
        $jogador.position = $engine.GetNewVector2($engine.MousePosX(),$engine.MousePosY())
        $jogador.DrawLine()
    }
    else {
        [Raylib_cs.Raylib]::DrawText("Congratulations, you lost!",0,0,40,$corBranco)
    }
    
    [Raylib_cs.Raylib]::ClearBackground($corPreto)

    $engine.ClearFrame();
}

$engine.CloseWindow();
