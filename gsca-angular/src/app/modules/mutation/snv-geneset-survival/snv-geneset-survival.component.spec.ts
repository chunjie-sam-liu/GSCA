import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { SnvGenesetSurvivalComponent } from './snv-geneset-survival.component';

describe('SnvGenesetSurvivalComponent', () => {
  let component: SnvGenesetSurvivalComponent;
  let fixture: ComponentFixture<SnvGenesetSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ SnvGenesetSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SnvGenesetSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
