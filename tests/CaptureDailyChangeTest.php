<?php

declare(strict_types=1);

namespace Tests;

use App\Models\DailyChange;
use App\Models\Portfolio;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;

class CaptureDailyChangeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->actingAs($user = User::factory()->create());

        $this->portfolio = Portfolio::factory()->create();
        Transaction::factory(5)->buy()->lastYear()->portfolio($this->portfolio->id)->symbol('AAPL')->create();
        $this->transaction = Transaction::factory()->sell()->lastMonth()->portfolio($this->portfolio->id)->symbol('AAPL')->create();
    }

    public function test_daily_change_for_portfolios()
    {
        // Run the command
        Artisan::call('capture:daily-change');

        // Assert the daily change was captured for the portfolio
        $this->assertDatabaseHas('daily_change', [
            'portfolio_id' => $this->portfolio->id,
        ]);

        $output = Artisan::output();
        $this->assertStringContainsString('Capturing daily change for', $output);

        $daily_change = DailyChange::where([
            'portfolio_id' => $this->portfolio->id,
        ])->get();

        $this->assertCount(1, $daily_change);

        $this->assertEqualsWithDelta(
            $this->transaction->sale_price - $this->transaction->cost_basis,
            $daily_change->first()->realized_gains,
            0.01
        );

    }
}
