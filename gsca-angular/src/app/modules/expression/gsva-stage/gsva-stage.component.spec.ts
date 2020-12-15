import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GsvaStageComponent } from './gsva-stage.component';

describe('GsvaStageComponent', () => {
  let component: GsvaStageComponent;
  let fixture: ComponentFixture<GsvaStageComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ GsvaStageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GsvaStageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
