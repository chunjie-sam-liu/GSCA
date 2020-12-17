import { DOCUMENT } from '@angular/common';
import { AfterViewInit, Component, ElementRef, Inject, OnInit, ViewChild } from '@angular/core';

@Component({
  selector: 'app-footer',
  templateUrl: './footer.component.html',
  styleUrls: ['./footer.component.css'],
})
export class FooterComponent implements OnInit, AfterViewInit {
  constructor(@Inject(DOCUMENT) private document, private elementRef: ElementRef) {}
  @ViewChild('revolvermaps') revolverMapsRef: ElementRef;
  @ViewChild('cloudfront') cloudFrontRef: ElementRef;

  ngOnInit(): void {}

  ngAfterViewInit() {
    const revolverMapsScript = this.document.createElement('script');
    revolverMapsScript.type = 'text/javascript';
    revolverMapsScript.src = '//rf.revolvermaps.com/0/0/7.js?i=5yt30uug30e&amp;m=1&amp;c=ff0000&amp;cr1=ffffff&amp;sx=0';
    revolverMapsScript.async = 'async';
    this.revolverMapsRef.nativeElement.appendChild(revolverMapsScript);

    const cloudFrontScript = this.document.createElement('script');
    cloudFrontScript.type = 'text/javascript';
    cloudFrontScript.src = 'https://d1bxh8uas1mnw7.cloudfront.net/assets/embed.js';
    cloudFrontScript.async = 'async';
    this.cloudFrontRef.nativeElement.appendChild(cloudFrontScript);
  }
}
