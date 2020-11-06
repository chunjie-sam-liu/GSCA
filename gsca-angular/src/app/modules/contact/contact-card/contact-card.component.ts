import { Component, OnInit, Input, ViewChild, ElementRef } from '@angular/core';

import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-contact-card',
  templateUrl: './contact-card.component.html',
  styleUrls: ['./contact-card.component.css'],
})
export class ContactCardComponent implements OnInit {
  @Input() author: any;

  // Template reference to the canvas element
  @ViewChild('canvasEl', { static: true }) canvasEl: ElementRef<HTMLCanvasElement>;

  public assets = environment.assets;


  // Canvas 2d context
  private context: CanvasRenderingContext2D;

  private drawEmail(email: string): void {
    this.context.font = '20px Arial';
    this.context.textBaseline = 'middle';
    this.context.textAlign = 'left';

    const x = 0;
    const y = (this.canvasEl.nativeElement as HTMLCanvasElement).height / 2;
    this.context.fillText('Email: ' + email, x, y);
  }

  constructor() {}

  ngOnInit(): void {
    this.context = (this.canvasEl.nativeElement as HTMLCanvasElement).getContext('2d');
    this.drawEmail(this.author.email);
  }
}

