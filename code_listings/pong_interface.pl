use strict;
use warnings;

use SDL;
use SDL::Event;
use SDL::Events;
use SDL::Rect;
use SDLx::App;
use SDLx::Controller::Interface;
use SDLx::Text;

package Ball;
use Class::XSAccessor {
    constructor => 'new',
    accessors => [ qw(x y w h v_x v_y) ],
};

sub check_collision {
    my ($ball, $paddle) = @_;

    if (    $ball->x   < ($paddle->x + $paddle->w)
        and $paddle->x < ($ball->x + $ball->w)
        and $ball->y   < ($paddle->y + $paddle->h)
        and $paddle->y < ($ball->y + $ball->h)
    ) {
        # reverse horizontal speed
        $ball->v_x( $ball->v_x * -1 );

        # mess a bit with vertical speed
        $ball->v_y( $ball->v_y + rand(1) - rand(1) );

        # collision came from the left!
        if ($ball->x < $paddle->x + $paddle->w / 2) {
            $ball->x( $paddle->x - $ball->w );
        }
        # collision came from the right
        else {
            $ball->x( $paddle->x + $paddle->w );
        }
        return 1;
    }
    return;
}

package Paddle;
use Class::XSAccessor {
    constructor => 'new',
    accessors => [ qw( x y w h v_y ) ],
};


package main;

my $app = SDLx::App->new( w => 500, h => 500, exit_on_quit => 1, dt => 0.02 );

my $paddle1 = Paddle->new( x => 10, y => $app->h/2, w => 10, h => 40, v_y => 0);
my $paddle2 = Paddle->new( x => $app->w - 20, y => $app->h/2, w => 10, h => 40);

my $ball = Ball->new( x => $app->w/2, y => $app->h/2, w => 10, h => 10, v_x => 3, v_y => 1.7 );

my $text = SDLx::Text->new( font => 'font.ttf', h_align => 'center' );

my ($p1_score, $p2_score) = (0, 0);

sub on_ball_move {
    my ($step, $app) = @_;

    my $x = $ball->x + ($ball->v_x * $step);
    my $y = $ball->y + ($ball->v_y * $step);

    # collision to the bottom of the screen
    if ( $y >= ($app->h - $ball->h) ) {
        $y = $app->h - $ball->h;
        $ball->v_y( $ball->v_y * -1 );
    }
    # collision to the top of the screen
    elsif ( $y <= 0 ) {
        $y = 0;
        $ball->v_y( $ball->v_y * -1 );
    }
    # collision to the right: player 1 score!
    elsif ( $x >= ($app->w - $ball->w) ) {
        $p1_score++;
        $x = $app->w / 2;
        $y = $app->h / 2;
    }
    # collision to the left: player 2 score!
    elsif ( $x <= 0 ) {
        $p2_score++;
        $x = $app->w / 2;
        $y = $app->h / 2;
    }
    $ball->x( $x );
    $ball->y( $y );
    
    # collisions with players
    $ball->check_collision( $paddle1 )
        or $ball->check_collision( $paddle2 );
}

$app->add_move_handler( \&on_ball_move );

sub on_paddle1_move {
    my ($step, $app) = @_;

    $paddle1->y( $paddle1->y + ($paddle1->v_y * $step) );
};

$app->add_move_handler( \&on_paddle1_move );

$app->add_event_handler( sub {
    my ($event, $app) = @_;

    if ( $event->type == SDL_KEYDOWN ) {
        if ($event->key_sym == SDLK_UP) {
            $paddle1->v_y(-2);
        }
        elsif ($event->key_sym == SDLK_DOWN ) {
            $paddle1->v_y(2);
        }
    }
    elsif ( $event->type == SDL_KEYUP ) {
        if ($event->key_sym == SDLK_UP
         or $event->key_sym == SDLK_DOWN
        ) {
            $paddle1->v_y(0);
        }
    }
});

sub AI_move {
    my ($step, $app) = @_;

    if ($ball->y > $paddle2->y) {
        $paddle2->v_y(2);
    }
    elsif ($ball->y < $paddle2->y) {
        $paddle2->v_y(-2);
    }
    else {
        $paddle2->v_y(0);
    }

    $paddle2->y( $paddle2->y + ($paddle2->v_y * $step) );
}

$app->add_move_handler( \&AI_move );


# our 'view' of the game
################################

$app->add_show_handler( sub {

    # first, we clear the screen
    $app->draw_rect( [0,0,$app->w, $app->h], 0x000000);

    # then we render the ball
    $app->draw_rect( [$ball->x, $ball->y, $ball->w, $ball->h], 0xFF0000FF );

    # then we render each paddle
    $app->draw_rect( [$paddle1->x, $paddle1->y, $paddle1->w, $paddle1->h], 0xFF0000FF );
    $app->draw_rect( [$paddle2->x, $paddle2->y, $paddle2->w, $paddle2->h], 0xFF0000FF );

    # ... and each player's score!
    $text->write_to($app, "$p1_score x $p2_score");

    # finally, we update the screen
    $app->update;
});

$app->run();

