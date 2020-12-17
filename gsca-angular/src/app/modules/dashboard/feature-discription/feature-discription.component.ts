import { Component, OnInit } from '@angular/core';
import features from 'src/app/shared/constants/features';
import feature from 'src/app/shared/constants/features';

@Component({
  selector: 'app-feature-discription',
  templateUrl: './feature-discription.component.html',
  styleUrls: ['./feature-discription.component.css'],
})
export class FeatureDiscriptionComponent implements OnInit {
  public features = features;
  constructor() {}

  ngOnInit(): void {}
}
